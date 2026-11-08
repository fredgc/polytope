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

import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';

import 'xr_support.dart';

XRSupport getXRSupport() {
  return AndroidXRSupport();
}

class AndroidXRSupport extends XRSupport {
  @override
  Future<void> checkSupport() async {
    print("BLUE: Checking AR support for Android...");
    // Simple check: if we are on Android, we'll try to support it.
    // In a real app, we'd use a more robust check.
    supported = true;
  }

  @override
  Future<bool> switchToXR() async {
    print("BLUE: Switching to AR on Android.");
    isActive = true;
    return true;
  }

  @override
  Widget buildScene(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Android AR View")),
      body: ARView(
        onARViewCreated: onARViewCreated,
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    print("BLUE: AR View Created!");
    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: true,
      handleTaps: false,
    );
    arObjectManager.onInitialize();
  }
}
