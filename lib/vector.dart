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

// A vector in R^d.
class Vector {
  static final int d = 5; // Maximum dimension of the world.
  static final Vector zero = Vector();
  List<double> x = List.filled(d, 0.0);

  Vector(); // Create a 0 length vector.

  Vector.unit(int i) {
    // Create a unit vector in direction i.
    x[i] = 1.0;
  }

  Vector.from(Vector other) : x = List.from(other.x);

  void scale(double s) {
    for (int i = 0; i < d; i++) x[i] *= s;
  }

  void add(Vector other) {
    for (int i = 0; i < d; i++) x[i] = x[i] + other.x[i];
  }

  void copy(Vector other) {
    for (int i = 0; i < d; i++) x[i] = other.x[i];
  }

  Vector operator +(Vector other) {
    Vector result = Vector();
    for (int i = 0; i < d; i++) result.x[i] = x[i] + other.x[i];
    return result;
  }

  Vector operator -(Vector other) {
    Vector result = Vector();
    for (int i = 0; i < d; i++) result.x[i] = x[i] - other.x[i];
    return result;
  }

  Vector operator *(double scalar) {
    Vector result = Vector();
    for (int i = 0; i < d; i++) result.x[i] = scalar * x[i];
    return result;
  }

  double dot(Vector other) {
    // inner product.
    double result = 0.0;
    for (int i = 0; i < d; i++) result += x[i] * other.x[i];
    return result;
  }

  double norm() {
    return math.sqrt(this.dot(this));
  }

  String toString() {
    return "< " + x.map((v) => "${zzz(v)}").join(", ") + ">";
  }
}

double norm(Vector v) => v.norm();

// XXX -- this does not seem to work.
// extension VectorMath on double {
//   // Scalar product.
//   Vector operator *(Vector vec) {
//     Vector result = Vector();
//     for (int i = 0; i < Vector.d; i++) result.x[i] = this * vec.x[i];
//     return result;
//   }
// }

// A Point in R^d, with information about being projected into R^2.
class Point extends Vector {
  int id = -1; // An id of -1 means it is unique.
  double sx = 0, sy = 0, sz = 0; // Screen coordinates. sz is for clipping.

  Point({this.id = -1});
  Point.from(Vector other) : super.from(other);

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (id == -1) return false;
    if (other is Point) {
      if (this.id == other.id) return true;
    }
    return false;
  }

  void permute(Permutation p) {
    id = p.map(id);
  }

  String toString() {
    return (id == -1 ? "P?" : "P${id}");
  }
}
