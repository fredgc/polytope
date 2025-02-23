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

import "transform.dart";
import "polytope.dart";
import "vector.dart";

String zzz(var vec) {
  return DebugPrint.pad_zzz > 0
      ? zzz2(vec).padLeft(DebugPrint.pad_zzz)
      : zzz2(vec);
}

String zzz2(var vec) {
  if (vec is Offset) {
    return "o(${zzz(vec.dx)}, ${zzz(vec.dy)})";
  }
  if (vec is Vector2) {
    return "(${zzz(vec.x)}, ${zzz(vec.y)})";
  }
  if (vec is List) {
    return "[" + vec.map((v) => zzz(v)).join(", ") + "]";
  }
  if (vec is Point) {
    return "$vec[" + vec.x.map((v) => zzz(v)).join(", ") + "]";
  }
  if (vec is Vertex) {
    return "$vec[" + vec.vertex.x.map((v) => zzz(v)).join(", ") + "]";
  }
  if (vec is double) {
    if (vec.isNaN) {
      return "NaN";
    }
    if (vec.isInfinite) {
      return "inf";
    }
    if (vec > 50 || vec < -50) {
      return "${vec.round()}";
    }
    return "${vec.toStringAsPrecision(3)}";
  }
  return "$vec";
}

class DebugPrint {
  static String indent = "- ";
  static int print_debug = 0;
  static int pad_zzz = 7;

  static void dprint(String s, {int depth = 0}) {
    if (print_debug > 0) {
      String extra_indent = indent;
      for (int i = 0; i < depth; i++) extra_indent = extra_indent + "  ";
      print("$extra_indent$s");
    }
  }

  static void printPoly(Polytope p) {
    if (print_debug > 0) p.printAll(indent: indent + ". ");
  }

  static String incIndent(String s) {
    String old = indent;
    indent = indent + s;
    return old;
  }

  static void decIndent(String old) {
    indent = old;
  }
}

void dprint(String s, {int depth = 0}) {
  DebugPrint.dprint(s, depth: depth);
}

// This class is used to test and debug long initialization times.  It is useful
// when testing splash screens and other events that are usually short lived.
class DebugSleep {
  static DebugSleep instance = DebugSleep();
  // Set this to true in order to add extra delays.
  static bool add_delay = false;

  Future<void> sleep(String text, Duration duration) async {
    if (add_delay) {
      print("ORANGE: Debug time $text.");
      await Future.delayed(duration);
      print("ORANGE: After debug time $text.");
    }
  }
}

Future<void> dsleep(String text, int duration) {
  return DebugSleep.instance.sleep(text, Duration(seconds: duration));
}
