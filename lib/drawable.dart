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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import "printer.dart";
import "vector.dart";
import 'polytope.dart';

abstract interface class Drawable {
  void paint(Canvas canvas);
  void dumpDebugInfo();
}

class Dot implements Drawable {
  Vertex v;
  Point pt;
  double radius = 2.0;
  Color color;

  Dot(this.v, this.color) : pt = v.vertex;

  void paint(Canvas canvas) {
    Paint paint = Paint()..color = color;
    Offset c = Offset(pt.sx, pt.sy);
    canvas.drawCircle(c, radius, paint);
    dprint("Painting $this");
  }

  String toString() {
    return "Dot-${v.id}";
  }

  void dumpDebugInfo() {
    print("  $this -> ${zzz(v)}");
  }
}

class LineSegment implements Drawable {
  Polytope edge;
  Point a = Point();
  Point b = Point();
  Color color;

  LineSegment(this.edge, this.color) {
    assert(edge.cells.length == 2);
    Vertex v1 = edge.cells.elementAt(0) as Vertex;
    Vertex v2 = edge.cells.elementAt(1) as Vertex;
    a = v1.vertex;
    b = v2.vertex;
  }

  void paint(Canvas canvas) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    Offset p1 = Offset(a.sx, a.sy);
    Offset p2 = Offset(b.sx, b.sy);
    canvas.drawLine(p1, p2, paint);
    dprint("Painting $this: ${zzz(p1)} - ${zzz(p2)}");
  }

  String toString() {
    return "Seg $a-$b";
  }

  void dumpDebugInfo() {
    print("  LineSegment $a to $b");
  }
}
