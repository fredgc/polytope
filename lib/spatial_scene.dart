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

import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'color.dart';
import 'polytope.dart';
import 'scene.dart';
import 'slice.dart';
import 'transform.dart';
import 'vector.dart';

/// A 3D sphere instance for rendering in XR.
class SphereInstance {
  final double x;
  final double y;
  final double z;
  final double radius;
  final Color color;

  const SphereInstance({
    required this.x,
    required this.y,
    required this.z,
    required this.radius,
    required this.color,
  });

  /// Writes 8 floats into [buffer] starting at [offset]:
  /// `[x, y, z, radius, r, g, b, a]`.
  void writeToBuffer(Float32List buffer, int offset) {
    buffer[offset] = x;
    buffer[offset + 1] = y;
    buffer[offset + 2] = z;
    buffer[offset + 3] = radius;
    buffer[offset + 4] = color.red / 255.0;
    buffer[offset + 5] = color.green / 255.0;
    buffer[offset + 6] = color.blue / 255.0;
    buffer[offset + 7] = color.opacity;
  }
}

/// A 3D cylinder (tube) instance for rendering in XR.
class CylinderInstance {
  final double x1;
  final double y1;
  final double z1;
  final double x2;
  final double y2;
  final double z2;
  final double radius;
  final Color color;

  const CylinderInstance({
    required this.x1,
    required this.y1,
    required this.z1,
    required this.x2,
    required this.y2,
    required this.z2,
    required this.radius,
    required this.color,
  });

  /// Writes 12 floats into [buffer] starting at [offset]:
  /// `[x1, y1, z1, x2, y2, z2, radius, r, g, b, a, 0.0]`.
  void writeToBuffer(Float32List buffer, int offset) {
    buffer[offset] = x1;
    buffer[offset + 1] = y1;
    buffer[offset + 2] = z1;
    buffer[offset + 3] = x2;
    buffer[offset + 4] = y2;
    buffer[offset + 5] = z2;
    buffer[offset + 6] = radius;
    buffer[offset + 7] = color.red / 255.0;
    buffer[offset + 8] = color.green / 255.0;
    buffer[offset + 9] = color.blue / 255.0;
    buffer[offset + 10] = color.opacity;
    buffer[offset + 11] = 0.0;
  }
}

/// Spatial 3D representation of a polytope and its slice, ready for XR rendering.
class SpatialScene {
  /// Overall scale factor for world space (in meters, e.g. 0.35m radius).
  double worldScale = 0.35;

  /// Default radii in meters.
  double vertexRadius = 0.018;
  double edgeRadius = 0.007;
  double sliceVertexRadius = 0.024;
  double sliceEdgeRadius = 0.010;

  final List<SphereInstance> spheres = [];
  final List<CylinderInstance> cylinders = [];

  Float32List _sphereBuffer = Float32List(0);
  Float32List _cylinderBuffer = Float32List(0);

  Float32List get sphereBuffer => _sphereBuffer;
  Float32List get cylinderBuffer => _cylinderBuffer;

  int get sphereCount => spheres.length;
  int get cylinderCount => cylinders.length;

  /// Updates spatial geometry from the 2D [scene].
  void updateFromScene(Scene scene) {
    update(
      scene.polytope,
      scene.slice,
      scene.transform,
      polyColor: Scene.poly_color.value,
      sliceColor: Slice.slice_color.value,
    );
  }

  /// Updates spatial geometry directly from polytope and slice parameters.
  void update(
    Polytope polytope,
    Slice? slice,
    CoordinateTransform transform, {
    Color polyColor = Colors.white,
    Color sliceColor = Colors.yellow,
  }) {
    spheres.clear();
    cylinders.clear();

    // 1. Add polytope vertices (shaded spheres).
    for (Vertex v in polytope.vertices) {
      Point p = v.vertex;
      spheres.add(SphereInstance(
        x: p.wx * worldScale,
        y: p.wy * worldScale,
        z: p.wz * worldScale,
        radius: vertexRadius,
        color: polyColor,
      ));
    }

    // 2. Add polytope edges (shaded cylinders / tubes).
    for (Polytope edge in polytope.edges) {
      if (edge.cells.length == 2) {
        Vertex v1 = edge.cells.elementAt(0) as Vertex;
        Vertex v2 = edge.cells.elementAt(1) as Vertex;
        Point p1 = v1.vertex;
        Point p2 = v2.vertex;
        cylinders.add(CylinderInstance(
          x1: p1.wx * worldScale,
          y1: p1.wy * worldScale,
          z1: p1.wz * worldScale,
          x2: p2.wx * worldScale,
          y2: p2.wy * worldScale,
          z2: p2.wz * worldScale,
          radius: edgeRadius,
          color: polyColor,
        ));
      }
    }

    // 3. Add slice elements if active.
    if (slice != null) {
      for (Intersection item in slice.intersections) {
        if (!item.visible) continue;

        if (item is SingularDot) {
          Point p = item.pt.vertex;
          spheres.add(SphereInstance(
            x: p.wx * worldScale,
            y: p.wy * worldScale,
            z: p.wz * worldScale,
            radius: sliceVertexRadius,
            color: sliceColor,
          ));
        } else if (item is SlideDot) {
          spheres.add(SphereInstance(
            x: item.wx * worldScale,
            y: item.wy * worldScale,
            z: item.wz * worldScale,
            radius: sliceVertexRadius,
            color: sliceColor,
          ));
        } else if (item is SingularEdge) {
          Point p1 = item.a.pt.vertex;
          Point p2 = item.b.pt.vertex;
          cylinders.add(CylinderInstance(
            x1: p1.wx * worldScale,
            y1: p1.wy * worldScale,
            z1: p1.wz * worldScale,
            x2: p2.wx * worldScale,
            y2: p2.wy * worldScale,
            z2: p2.wz * worldScale,
            radius: sliceEdgeRadius,
            color: sliceColor,
          ));
        } else if (item is SlideEdge) {
          cylinders.add(CylinderInstance(
            x1: item.a.wx * worldScale,
            y1: item.a.wy * worldScale,
            z1: item.a.wz * worldScale,
            x2: item.b.wx * worldScale,
            y2: item.b.wy * worldScale,
            z2: item.b.wz * worldScale,
            radius: sliceEdgeRadius,
            color: sliceColor,
          ));
        }
      }
    }

    // 4. Pack into contiguous Float32List buffers for GPU upload.
    _packBuffers();
  }

  void _packBuffers() {
    int sphereFloats = spheres.length * 8;
    if (_sphereBuffer.length != sphereFloats) {
      _sphereBuffer = Float32List(sphereFloats);
    }
    for (int i = 0; i < spheres.length; i++) {
      spheres[i].writeToBuffer(_sphereBuffer, i * 8);
    }

    int cylinderFloats = cylinders.length * 12;
    if (_cylinderBuffer.length != cylinderFloats) {
      _cylinderBuffer = Float32List(cylinderFloats);
    }
    for (int i = 0; i < cylinders.length; i++) {
      cylinders[i].writeToBuffer(_cylinderBuffer, i * 12);
    }
  }
}
