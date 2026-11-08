// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:web/web.dart' as web;

import 'spatial_scene.dart';

/// WebGL2 renderer for drawing shaded 3D spheres (vertices) and tubes (edges)
/// using hardware instancing.
class WebXRRenderer {
  final web.WebGL2RenderingContext gl;

  web.WebGLProgram? _sphereProgram;
  web.WebGLProgram? _cylinderProgram;

  web.WebGLVertexArrayObject? _sphereVao;
  web.WebGLBuffer? _sphereInstanceVbo;
  int _sphereIndexCount = 0;

  web.WebGLVertexArrayObject? _cylinderVao;
  web.WebGLBuffer? _cylinderInstanceVbo;
  int _cylinderIndexCount = 0;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  WebXRRenderer(this.gl) {
    _init();
  }

  void _init() {
    _sphereProgram =
        _createProgram(_sphereVertexShaderSource, _fragmentShaderSource);
    _cylinderProgram =
        _createProgram(_cylinderVertexShaderSource, _fragmentShaderSource);

    if (_sphereProgram == null || _cylinderProgram == null) {
      print('RED: WebXRRenderer failed to compile shader programs.');
      return;
    }

    _initSphereGeometry();
    _initCylinderGeometry();
    _initialized = true;
  }

  web.WebGLProgram? _createProgram(String vertSrc, String fragSrc) {
    final vertShader = gl.createShader(web.WebGLRenderingContext.VERTEX_SHADER);
    if (vertShader == null) return null;
    gl.shaderSource(vertShader, vertSrc);
    gl.compileShader(vertShader);
    final vertSuccess = (gl.getShaderParameter(
            vertShader, web.WebGLRenderingContext.COMPILE_STATUS) as JSBoolean)
        .toDart;
    if (!vertSuccess) {
      final info = gl.getShaderInfoLog(vertShader);
      print('RED: Vertex Shader Compile Error: $info');
      gl.deleteShader(vertShader);
      return null;
    }

    final fragShader =
        gl.createShader(web.WebGLRenderingContext.FRAGMENT_SHADER);
    if (fragShader == null) return null;
    gl.shaderSource(fragShader, fragSrc);
    gl.compileShader(fragShader);
    final fragSuccess = (gl.getShaderParameter(
            fragShader, web.WebGLRenderingContext.COMPILE_STATUS) as JSBoolean)
        .toDart;
    if (!fragSuccess) {
      final info = gl.getShaderInfoLog(fragShader);
      print('RED: Fragment Shader Compile Error: $info');
      gl.deleteShader(fragShader);
      return null;
    }

    final program = gl.createProgram();
    if (program == null) return null;
    gl.attachShader(program, vertShader);
    gl.attachShader(program, fragShader);
    gl.linkProgram(program);
    final linkSuccess = (gl.getProgramParameter(
            program, web.WebGLRenderingContext.LINK_STATUS) as JSBoolean)
        .toDart;
    if (!linkSuccess) {
      final info = gl.getProgramInfoLog(program);
      print('RED: Shader Link Error: $info');
      gl.deleteProgram(program);
      return null;
    }

    return program;
  }

  void _initSphereGeometry() {
    final vao = gl.createVertexArray();
    gl.bindVertexArray(vao);
    _sphereVao = vao;

    const int rings = 10;
    const int sectors = 14;
    final List<double> vertexData = []; // pos.xyz, norm.xyz
    final List<int> indexData = [];

    for (int r = 0; r <= rings; r++) {
      final double phi = math.pi * r / rings;
      final double y = math.cos(phi);
      final double sinPhi = math.sin(phi);

      for (int s = 0; s <= sectors; s++) {
        final double theta = 2.0 * math.pi * s / sectors;
        final double x = sinPhi * math.cos(theta);
        final double z = sinPhi * math.sin(theta);

        // Position
        vertexData.add(x);
        vertexData.add(y);
        vertexData.add(z);
        // Normal
        vertexData.add(x);
        vertexData.add(y);
        vertexData.add(z);
      }
    }

    for (int r = 0; r < rings; r++) {
      for (int s = 0; s < sectors; s++) {
        final int first = r * (sectors + 1) + s;
        final int second = first + sectors + 1;

        indexData.add(first);
        indexData.add(second);
        indexData.add(first + 1);

        indexData.add(second);
        indexData.add(second + 1);
        indexData.add(first + 1);
      }
    }
    _sphereIndexCount = indexData.length;

    // VBO for mesh
    final meshVbo = gl.createBuffer();
    gl.bindBuffer(web.WebGLRenderingContext.ARRAY_BUFFER, meshVbo);
    gl.bufferData(
      web.WebGLRenderingContext.ARRAY_BUFFER,
      Float32List.fromList(vertexData).toJS,
      web.WebGLRenderingContext.STATIC_DRAW,
    );

    // EBO
    final ebo = gl.createBuffer();
    gl.bindBuffer(web.WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, ebo);
    gl.bufferData(
      web.WebGLRenderingContext.ELEMENT_ARRAY_BUFFER,
      Uint16List.fromList(indexData).toJS,
      web.WebGLRenderingContext.STATIC_DRAW,
    );

    // Attrib 0: aVertexPosition (vec3)
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 3, web.WebGLRenderingContext.FLOAT, false, 24, 0);

    // Attrib 1: aVertexNormal (vec3)
    gl.enableVertexAttribArray(1);
    gl.vertexAttribPointer(
        1, 3, web.WebGLRenderingContext.FLOAT, false, 24, 12);

    // Instance VBO
    _sphereInstanceVbo = gl.createBuffer();
    gl.bindBuffer(web.WebGLRenderingContext.ARRAY_BUFFER, _sphereInstanceVbo);

    // Attrib 2: aSpherePos (vec3)
    gl.enableVertexAttribArray(2);
    gl.vertexAttribPointer(2, 3, web.WebGLRenderingContext.FLOAT, false, 32, 0);
    gl.vertexAttribDivisor(2, 1);

    // Attrib 3: aSphereRadius (float)
    gl.enableVertexAttribArray(3);
    gl.vertexAttribPointer(
        3, 1, web.WebGLRenderingContext.FLOAT, false, 32, 12);
    gl.vertexAttribDivisor(3, 1);

    // Attrib 4: aSphereColor (vec4)
    gl.enableVertexAttribArray(4);
    gl.vertexAttribPointer(
        4, 4, web.WebGLRenderingContext.FLOAT, false, 32, 16);
    gl.vertexAttribDivisor(4, 1);

    gl.bindVertexArray(null);
  }

  void _initCylinderGeometry() {
    final vao = gl.createVertexArray();
    gl.bindVertexArray(vao);
    _cylinderVao = vao;

    const int segments = 14;
    final List<double> vertexData = [];
    final List<int> indexData = [];

    for (int s = 0; s <= segments; s++) {
      final double theta = 2.0 * math.pi * s / segments;
      final double x = math.cos(theta);
      final double y = math.sin(theta);

      // Bottom vertex (z = 0)
      vertexData.add(x);
      vertexData.add(y);
      vertexData.add(0.0);
      vertexData.add(x);
      vertexData.add(y);
      vertexData.add(0.0);

      // Top vertex (z = 1)
      vertexData.add(x);
      vertexData.add(y);
      vertexData.add(1.0);
      vertexData.add(x);
      vertexData.add(y);
      vertexData.add(0.0);
    }

    for (int s = 0; s < segments; s++) {
      final int i0 = s * 2;
      final int i1 = i0 + 1;
      final int i2 = i0 + 2;
      final int i3 = i0 + 3;

      indexData.add(i0);
      indexData.add(i1);
      indexData.add(i2);

      indexData.add(i1);
      indexData.add(i3);
      indexData.add(i2);
    }
    _cylinderIndexCount = indexData.length;

    // VBO
    final meshVbo = gl.createBuffer();
    gl.bindBuffer(web.WebGLRenderingContext.ARRAY_BUFFER, meshVbo);
    gl.bufferData(
      web.WebGLRenderingContext.ARRAY_BUFFER,
      Float32List.fromList(vertexData).toJS,
      web.WebGLRenderingContext.STATIC_DRAW,
    );

    // EBO
    final ebo = gl.createBuffer();
    gl.bindBuffer(web.WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, ebo);
    gl.bufferData(
      web.WebGLRenderingContext.ELEMENT_ARRAY_BUFFER,
      Uint16List.fromList(indexData).toJS,
      web.WebGLRenderingContext.STATIC_DRAW,
    );

    // Attrib 0: aVertexPosition (vec3)
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 3, web.WebGLRenderingContext.FLOAT, false, 24, 0);

    // Attrib 1: aVertexNormal (vec3)
    gl.enableVertexAttribArray(1);
    gl.vertexAttribPointer(
        1, 3, web.WebGLRenderingContext.FLOAT, false, 24, 12);

    // Instance VBO
    _cylinderInstanceVbo = gl.createBuffer();
    gl.bindBuffer(web.WebGLRenderingContext.ARRAY_BUFFER, _cylinderInstanceVbo);

    // Attrib 2: aP1 (vec3)
    gl.enableVertexAttribArray(2);
    gl.vertexAttribPointer(2, 3, web.WebGLRenderingContext.FLOAT, false, 48, 0);
    gl.vertexAttribDivisor(2, 1);

    // Attrib 3: aP2 (vec3)
    gl.enableVertexAttribArray(3);
    gl.vertexAttribPointer(
        3, 3, web.WebGLRenderingContext.FLOAT, false, 48, 12);
    gl.vertexAttribDivisor(3, 1);

    // Attrib 4: aCylinderRadius (float)
    gl.enableVertexAttribArray(4);
    gl.vertexAttribPointer(
        4, 1, web.WebGLRenderingContext.FLOAT, false, 48, 24);
    gl.vertexAttribDivisor(4, 1);

    // Attrib 5: aCylinderColor (vec4)
    gl.enableVertexAttribArray(5);
    gl.vertexAttribPointer(
        5, 4, web.WebGLRenderingContext.FLOAT, false, 48, 28);
    gl.vertexAttribDivisor(5, 1);

    gl.bindVertexArray(null);
  }

  /// Renders the spatial scene for an eye view with given [projectionMatrix],
  /// [viewMatrix], and optional [modelMatrix].
  void render({
    required SpatialScene spatialScene,
    required Float32List projectionMatrix,
    required Float32List viewMatrix,
    Float32List? modelMatrix,
  }) {
    if (!_initialized) return;

    gl.enable(web.WebGLRenderingContext.DEPTH_TEST);
    gl.enable(web.WebGLRenderingContext.BLEND);
    gl.blendFunc(web.WebGLRenderingContext.SRC_ALPHA,
        web.WebGLRenderingContext.ONE_MINUS_SRC_ALPHA);

    final effectiveModelMatrix = modelMatrix ?? defaultModelMatrix();

    // 1. Render Cylinders (Tubes)
    if (spatialScene.cylinderCount > 0) {
      gl.useProgram(_cylinderProgram);
      _setUniforms(_cylinderProgram!, projectionMatrix, viewMatrix,
          effectiveModelMatrix);

      gl.bindBuffer(
          web.WebGLRenderingContext.ARRAY_BUFFER, _cylinderInstanceVbo);
      gl.bufferData(
        web.WebGLRenderingContext.ARRAY_BUFFER,
        spatialScene.cylinderBuffer.toJS,
        web.WebGLRenderingContext.DYNAMIC_DRAW,
      );

      gl.bindVertexArray(_cylinderVao);
      gl.drawElementsInstanced(
        web.WebGLRenderingContext.TRIANGLES,
        _cylinderIndexCount,
        web.WebGLRenderingContext.UNSIGNED_SHORT,
        0,
        spatialScene.cylinderCount,
      );
    }

    // 2. Render Spheres (Vertices)
    if (spatialScene.sphereCount > 0) {
      gl.useProgram(_sphereProgram);
      _setUniforms(
          _sphereProgram!, projectionMatrix, viewMatrix, effectiveModelMatrix);

      gl.bindBuffer(web.WebGLRenderingContext.ARRAY_BUFFER, _sphereInstanceVbo);
      gl.bufferData(
        web.WebGLRenderingContext.ARRAY_BUFFER,
        spatialScene.sphereBuffer.toJS,
        web.WebGLRenderingContext.DYNAMIC_DRAW,
      );

      gl.bindVertexArray(_sphereVao);
      gl.drawElementsInstanced(
        web.WebGLRenderingContext.TRIANGLES,
        _sphereIndexCount,
        web.WebGLRenderingContext.UNSIGNED_SHORT,
        0,
        spatialScene.sphereCount,
      );
    }

    gl.bindVertexArray(null);
    gl.useProgram(null);
  }

  void _setUniforms(
    web.WebGLProgram program,
    Float32List projectionMatrix,
    Float32List viewMatrix,
    Float32List modelMatrix,
  ) {
    final uProj = gl.getUniformLocation(program, 'uProjectionMatrix');
    final uView = gl.getUniformLocation(program, 'uViewMatrix');
    final uModel = gl.getUniformLocation(program, 'uModelMatrix');
    final uLight = gl.getUniformLocation(program, 'uLightDir');

    gl.uniformMatrix4fv(uProj, false, projectionMatrix.toJS);
    gl.uniformMatrix4fv(uView, false, viewMatrix.toJS);
    gl.uniformMatrix4fv(uModel, false, modelMatrix.toJS);
    gl.uniform3f(uLight, 0.4, 0.8, 0.5);
  }

  /// Default model matrix placing the object 0.8m in front of the viewer at eye level.
  static Float32List defaultModelMatrix({double tz = -0.8, double ty = -0.05}) {
    final m = Float32List(16);
    m[0] = 1.0;
    m[5] = 1.0;
    m[10] = 1.0;
    m[15] = 1.0;
    m[13] = ty; // translate Y
    m[14] = tz; // translate Z
    return m;
  }

  // --- Shaders ---

  static const String _fragmentShaderSource = '''#version 300 es
precision highp float;

in vec3 vNormal;
in vec4 vColor;
in vec3 vWorldPos;

uniform vec3 uLightDir;

out vec4 fragColor;

void main() {
  vec3 N = normalize(vNormal);
  vec3 L = normalize(uLightDir);
  vec3 V = normalize(-vWorldPos);
  vec3 H = normalize(L + V);

  float ambient = 0.38;
  float diff = max(dot(N, L), 0.0) * 0.62;
  float spec = pow(max(dot(N, H), 0.0), 32.0) * 0.35;

  vec3 rgb = vColor.rgb * (ambient + diff) + vec3(spec);
  fragColor = vec4(rgb, vColor.a);
}
''';

  static const String _sphereVertexShaderSource = '''#version 300 es
precision highp float;

layout(location = 0) in vec3 aVertexPosition;
layout(location = 1) in vec3 aVertexNormal;

layout(location = 2) in vec3 aSpherePos;
layout(location = 3) in float aSphereRadius;
layout(location = 4) in vec4 aSphereColor;

uniform mat4 uProjectionMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uModelMatrix;

out vec3 vNormal;
out vec4 vColor;
out vec3 vWorldPos;

void main() {
  vec3 localPos = aSpherePos + aVertexPosition * aSphereRadius;
  vec4 worldPos = uModelMatrix * vec4(localPos, 1.0);
  vWorldPos = worldPos.xyz;
  vNormal = normalize(mat3(uModelMatrix) * aVertexNormal);
  vColor = aSphereColor;
  gl_Position = uProjectionMatrix * uViewMatrix * worldPos;
}
''';

  static const String _cylinderVertexShaderSource = '''#version 300 es
precision highp float;

layout(location = 0) in vec3 aVertexPosition;
layout(location = 1) in vec3 aVertexNormal;

layout(location = 2) in vec3 aP1;
layout(location = 3) in vec3 aP2;
layout(location = 4) in float aCylinderRadius;
layout(location = 5) in vec4 aCylinderColor;

uniform mat4 uProjectionMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uModelMatrix;

out vec3 vNormal;
out vec4 vColor;
out vec3 vWorldPos;

void main() {
  vec3 dir = aP2 - aP1;
  float len = length(dir);
  if (len < 0.00001) {
    gl_Position = vec4(0.0);
    return;
  }
  vec3 zAxis = dir / len;
  vec3 up = abs(zAxis.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
  vec3 xAxis = normalize(cross(up, zAxis));
  vec3 yAxis = cross(zAxis, xAxis);

  vec3 localPos = aP1 + (xAxis * aVertexPosition.x + yAxis * aVertexPosition.y) * aCylinderRadius + zAxis * (aVertexPosition.z * len);
  vec3 localNormal = normalize(xAxis * aVertexNormal.x + yAxis * aVertexNormal.y);

  vec4 worldPos = uModelMatrix * vec4(localPos, 1.0);
  vWorldPos = worldPos.xyz;
  vNormal = normalize(mat3(uModelMatrix) * localNormal);
  vColor = aCylinderColor;
  gl_Position = uProjectionMatrix * uViewMatrix * worldPos;
}
''';
}
