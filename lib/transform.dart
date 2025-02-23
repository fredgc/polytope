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

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:vector_math/vector_math.dart' show Vector2;

import "permute.dart";
import "printer.dart";
import "vector.dart";

// A transformation from R^d world coordinates to R^2 screen coordinates.
// It is not a linear transformation because we do a perspective projection from
// R^n to R^n-1.
class CoordinateTransform {
  Size size = Size(0, 0); // Screen size.

  Vector b = Vector(); // First translate by -b.
  double scale = 1.0; // Then multiply by scale.
  // Then rotate by the orthogonal matrix A.
  List<List<double>> A = List.filled(Vector.d, []);
  List<double> zolly = [
    0,
    0,
    0.05,
    0.1,
    0.25
  ]; // Perspective projection by 1/(1+zolly_i * x_i)
  // After that, the point should be in R^2. Scale to the screen.
  double zoom = 1.0;
  Vector2 offset = Vector2(0, 0); // Screen coords mapped to by (0,0).

  // When animating, we rotate in the planes specified by axis1 x axis2.
  List<double> speed = [0.0, 0.0];

  CoordinateTransform() {
    resetRotation();
  }

  bool sizeChanged(Size size) {
    return size != this.size;
  }

  void apply(List<Point> points) {
    for (Point p in points) {
      Vector temp = Vector();
      for (int i = 0; i < Vector.d; i++) {
        for (int j = 0; j < Vector.d; j++) {
          temp.x[i] += A[i][j] * (p.x[j] - b.x[j]) * scale;
        }
      }
      for (int j = zolly.length - 1; j > 1; j--) {
        for (int i = 0; i < j; i++) {
          temp.x[i] = temp.x[i] / (1.0 - zolly[j] * temp.x[j]);
        }
      }
      p.sx = offset.x + zoom * temp.x[0];
      p.sy = offset.y - zoom * temp.x[1];
      p.sz = zoom * temp.x[2];
      dprint("  Tran $p -> (${zzz(p.sx)}, ${zzz(p.sy)}, ${zzz(p.sz)})");
    }
  }

  void resetRotation() {
    for (int i = 0; i < A.length; i++) {
      A[i] = List.filled(Vector.d, 0.0);
      A[i][i] = 1.0;
    }
    b = Vector();
    offset = Vector2(size.width / 2, size.height / 2);
    // We do not change scale, zoom, or zolly.
  }

  void pan(double dx, double dy) {
    offset = Vector2(offset.x + dx, offset.y + dy);
  }

  void zollyBy(int i, double dx) {
    double dz = dx / zoom;
    zolly[i] *= (1 + dz);
    if (zolly[i] <= 0) zolly[i] = 0;
    final double min_zolly = 1e-6;
    if (dz > 0 && zolly[i] <= 0) zolly[i] = min_zolly;
    final double max_zolly = 0.99;
    if (zolly[i] > max_zolly) zolly[i] = max_zolly;
  }

  void scaleBy(double delta) {
    zoom = zoom * delta;
  }

  // Rotate the screen direction (dx,dy) against the unit vector u_i.
  // (dx,dy) is a vector in screen coordinates.
  void rotatePair(int i, double dx, double dy) {
    // This assumes that the screen is looking at a unit sphere.
    double theta1 = dx / zoom;
    double theta2 = -dy / zoom;
    rotate(0, i, theta1);
    rotate(1, i, theta2);
  }

  // Rotate in the plane u_e1, u_e2 by the angle theta in radians.
  void rotate(int e1, int e2, double theta) {
    // print("  rotate($e1, $e2, ${zzz(theta)})");
    // an angle of theta through e_1 and e_2.
    double ct = math.cos(theta);
    double st = math.sin(theta);
    for (int i = 0; i < A.length; i++) {
      double temp = ct * A[e1][i] + st * A[e2][i];
      A[e2][i] = -st * A[e1][i] + ct * A[e2][i];
      A[e1][i] = temp;
    }
  }

  bool updateTime(double dt) {
    if (speed[0] == 0.0 && speed[1] == 0.0) return false;
    double dtheta1 = speed[0] * dt;
    rotate(0, 2, dtheta1);
    double dtheta2 = speed[1] * dt;
    rotate(1, 2, dtheta2);
    return true;
  }

  void setSpeed(double dx, double dy) {
    speed = [dx / zoom, -dy / zoom];
    dprint("setSpeed = ${zzz(speed)}");
  }

  void resize(Size size) {
    dprint("BLUE: Size ${this.size} -> $size");
    if (this.size.width > 0) {
      // If we already have a size, then we just want to change the center,
      // and not the scales.
      offset = Vector2(
        offset.x + (size.width - this.size.width) / 2,
        offset.y + (size.height - this.size.height) / 2,
      );
    } else {
      // If there is no size yet, we also want to initialize the zoom.
      offset = Vector2(size.width / 2, size.height / 2);
      zoom = math.min(size.width, size.height) / 3.0;
    }
    this.size = size;
    // print("${zzz(size)}, offset=${zzz(offset)}, min = ${zzz(min)}, max = ${zzz(max)}, zoom = ${zzz(zoom)}");
  }

  void dumpDebugInfo() {
    print("Transform (size $size, scale = ${zzz(scale)}, zolly = $zolly)");
    print("  offset = ${zzz(offset)}");
    for (int i = 0; i < Vector.d; i++) {
      print("   [" +
          A[i].map((a) => "${zzz(a)}").join(", ") +
          "]   [${zzz(b.x[i])}]");
    }
  }
}
