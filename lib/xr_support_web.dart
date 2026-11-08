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

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:webxr/webxr.dart' as webxr;

import 'spatial_scene.dart';
import 'webxr_renderer.dart';
import 'xr_support.dart';

XRSupport getXRSupport() {
  return WebXRSupport();
}

class WebXRSupport extends XRSupport {
  bool vrSupported = false;
  bool arSupported = false;
  bool inlineSupported = false;

  @override
  Future<void> checkSupport() async {
    supported = await supportsXR();
  }

  Future<bool> supportsXR() async {
    final navigator = webxr.Navigator.$(web.window.navigator);
    final xr = navigator.xr;
    if (xr == null) {
      print('RED: WebXR is not supported in this browser.');
      return false;
    }

    try {
      final vr = await xr.isSessionSupported('immersive-vr'.toJS).toDart;
      vrSupported = vr.toDart;

      final ar = await xr.isSessionSupported('immersive-ar'.toJS).toDart;
      arSupported = ar.toDart;

      final inline = await xr.isSessionSupported('inline'.toJS).toDart;
      inlineSupported = inline.toDart;

      return vrSupported || arSupported || inlineSupported;
    } catch (e) {
      print('Error checking WebXR support: $e');
    }
    return false;
  }

  webxr.XRSessionMode get preferredMode {
    if (vrSupported) return 'immersive-vr'.toJS;
    if (arSupported) return 'immersive-ar'.toJS;
    return 'inline'.toJS;
  }

  String get preferredModeName {
    if (vrSupported) return 'VR (Headset)';
    if (arSupported) return 'AR (Passthrough)';
    return 'Inline 3D';
  }

  @override
  Future<bool> switchToXR() async {
    final navigator = webxr.Navigator.$(web.window.navigator);
    final xr = navigator.xr;
    if (xr == null) {
      print('RED: WebXR is not supported in this browser');
      return false;
    }
    isActive = true;
    return true;
  }

  @override
  Widget buildScene(BuildContext context) {
    return WebXRWidget(this);
  }
}

class WebXRWidget extends StatefulWidget {
  final WebXRSupport support;

  const WebXRWidget(this.support, {super.key});

  @override
  State<WebXRWidget> createState() => _WebXRWidgetState();
}

class _WebXRWidgetState extends State<WebXRWidget> {
  String _status = "Ready to start XR session";
  webxr.XRSession? _session;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // In WebXR, session start requires a direct user gesture (button tap).
  }

  Future<void> _startXR() async {
    if (_starting || _session != null) return;
    setState(() {
      _starting = true;
      _status = "Requesting XR session...";
    });

    try {
      final navigator = webxr.Navigator.$(web.window.navigator);
      final xr = navigator.xr;
      if (xr == null) {
        throw Exception('WebXR not supported');
      }

      final mode = widget.support.preferredMode;
      final session = await xr.requestSession(mode).toDart;

      // Create WebGL2 canvas context for stereoscopic rendering
      final canvas =
          web.document.createElement('canvas') as web.HTMLCanvasElement;
      final gl = canvas.getContext(
        'webgl2',
        {'xrCompatible': true}.jsify(),
      ) as web.WebGL2RenderingContext?;

      if (gl == null) {
        throw Exception('WebGL2 context creation failed');
      }

      final renderer = WebXRRenderer(gl);
      if (!renderer.isInitialized) {
        throw Exception('WebXRRenderer shader initialization failed');
      }

      final baseLayer = webxr.XRWebGLLayer(session, gl);
      (session as dynamic).updateRenderState({'baseLayer': baseLayer}.jsify());

      // Obtain reference space (try local first for 6DoF, fall back to viewer)
      web.XRReferenceSpace refSpace;
      try {
        refSpace = await session.requestReferenceSpace('local'.toJS).toDart
            as web.XRReferenceSpace;
      } catch (_) {
        refSpace = await session.requestReferenceSpace('viewer'.toJS).toDart
            as web.XRReferenceSpace;
      }

      setState(() {
        _session = session;
        _starting = false;
        _status = "XR Session Active (${widget.support.preferredModeName})";
      });

      // Handle session end
      session.onend = webxr.XRSessionEventHandler.$(((web.Event event) {
        if (mounted) {
          setState(() {
            _session = null;
            _status = "XR Session Ended";
          });
        }
        widget.support.isActive = false;
        widget.support.onExitXR?.call();
      }).toJS);

      // Start the render loop
      final spatialScene = SpatialScene();
      late webxr.XRFrameRequestCallback onFrameCallback;

      onFrameCallback = ((web.DOMHighResTimeStamp time, webxr.XRFrame frame) {
        if (_session == null || !widget.support.isActive) return;
        session.requestAnimationFrame(onFrameCallback);

        final pose = frame.getViewerPose(refSpace);
        if (pose != null) {
          gl.bindFramebuffer(
              web.WebGLRenderingContext.FRAMEBUFFER, baseLayer.framebuffer);
          gl.clearColor(0.0, 0.0, 0.0, 0.0);
          gl.clear(web.WebGLRenderingContext.COLOR_BUFFER_BIT |
              web.WebGLRenderingContext.DEPTH_BUFFER_BIT);

          if (widget.support.scene != null) {
            spatialScene.updateFromScene(widget.support.scene!);
          }

          final views = pose.views.toDart;
          for (final v in views) {
            final view = v as webxr.XRView;
            final viewport = baseLayer.getViewport(view);
            if (viewport != null) {
              gl.viewport(
                  viewport.x, viewport.y, viewport.width, viewport.height);
            }

            final projMatrix = view.projectionMatrix.toDart;
            final viewMatrix = view.transform.inverse.matrix.toDart;

            renderer.render(
              spatialScene: spatialScene,
              projectionMatrix: projMatrix,
              viewMatrix: viewMatrix,
            );
          }
        }
      }).toJS;

      session.requestAnimationFrame(onFrameCallback);
    } catch (e) {
      print('RED: Error starting XR session: $e');
      if (mounted) {
        setState(() {
          _starting = false;
          _status = "Failed to start XR session: $e";
        });
      }
      widget.support.isActive = false;
    }
  }

  Future<void> _endXR() async {
    if (_session != null) {
      await _session!.end().toDart;
    } else {
      widget.support.isActive = false;
      widget.support.onExitXR?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Polytope WebXR"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Return to 2D View",
          onPressed: _endXR,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.view_in_ar,
                  size: 72, color: Colors.indigoAccent),
              const SizedBox(height: 20),
              Text(
                _status,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (_session == null)
                ElevatedButton.icon(
                  onPressed: _starting ? null : _startXR,
                  icon: const Icon(Icons.play_arrow),
                  label: Text("Enter ${widget.support.preferredModeName}"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _endXR,
                  icon: const Icon(Icons.stop),
                  label: const Text("End XR Session"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _endXR,
                icon: const Icon(Icons.close),
                label: const Text("Exit to 2D Mode"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
