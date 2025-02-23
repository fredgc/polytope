// Copyright 2024 Google LLC
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

import 'package:flutter/material.dart';

import "printer.dart";
import 'scene.dart';

class MyAnimator {
  static final int clock_time = 10; // restart animation loop after 10 seconds.
  AnimationController controller;
  double previous_clock = 0.0;
  Scene scene;
  int ticks = 0;

  MyAnimator(SingleTickerProviderStateMixin tick_provider, this.scene)
      : controller = AnimationController(
          vsync: tick_provider,
          duration: Duration(seconds: clock_time),
          upperBound: clock_time.toDouble(),
        ) {
    controller.view.addListener(hearTick);
    controller.addStatusListener((status) {
      // print("Animation status: $status, value = ${zzz(controller.value)}");
      if (status == AnimationStatus.completed) {
        // Warn the scene that the animation is going to reset.
        onComplete();
      }
    });
  }

  String debugPrint() {
    return (" a${zzz(controller.value)}($ticks)");
  }

  void hearTick() {
    ticks++;
    double dt = controller.value - previous_clock;
    bool changed = scene.updateTime(dt);
    previous_clock = controller.value;
    if (!changed) {
      dprint("Animator: no change. pausing.");
      pause();
    }
  }

  void onComplete() {
    dprint("Animator onComplete. previous = ${zzz(previous_clock)}");
    previous_clock = 0;
    controller.reset();
    controller.forward();
  }

  void dispose() {
    controller.dispose();
  }

  void pause() => controller.stop();
  void play() {
    // print("GREEN: Animator is starting.");
    controller.forward(from: controller.value);
  }

  bool get isAnimating => controller.isAnimating;
}
