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
import "vector.dart";
import 'polytope.dart';
import 'scene.dart';

abstract interface class Drawable {
  void paint(Canvas canvas);
  void dumpDebugInfo();
}

abstract class ClippableEdge implements Drawable {
  Point get ptA;
  Point get ptB;
  bool get isEdgeVisible => true;

  // Polytope edge that this segment lies on or terminates at (if applicable).
  Polytope? get sourceEdge => null;
  Vertex? get vertexA => null;
  Vertex? get vertexB => null;

  void resetGaps();
  void addGap(double t0, double t1);
}

class Dot implements Drawable {
  Vertex v;
  Point pt;
  double get radius => Scene.vertex_radius.value;
  Color color;

  Dot(this.v, this.color) : pt = v.vertex;

  @override
  void paint(Canvas canvas) {
    Paint paint = Paint()..color = color;
    Offset c = Offset(pt.sx, pt.sy);
    canvas.drawCircle(c, radius, paint);
    dprint("Painting $this");
  }

  @override
  String toString() {
    return "Dot-${v.id}";
  }

  @override
  void dumpDebugInfo() {
    print("  $this -> ${zzz(v)}");
  }
}

class LineSegment implements ClippableEdge {
  Polytope edge;
  Point a = Point();
  Point b = Point();
  Color color;
  List<double>? gaps; // List of pairs [tStart, tEnd] representing gaps to cut.

  @override
  Point get ptA => a;
  @override
  Point get ptB => b;
  @override
  bool get isEdgeVisible => true;
  @override
  Polytope get sourceEdge => edge;
  @override
  Vertex get vertexA => edge.cells.elementAt(0) as Vertex;
  @override
  Vertex get vertexB => edge.cells.elementAt(1) as Vertex;

  LineSegment(this.edge, this.color) {
    assert(edge.cells.length == 2);
    Vertex v1 = edge.cells.elementAt(0) as Vertex;
    Vertex v2 = edge.cells.elementAt(1) as Vertex;
    a = v1.vertex;
    b = v2.vertex;
  }

  @override
  void resetGaps() {
    gaps = null;
  }

  @override
  void addGap(double t0, double t1) {
    gaps ??= [];
    double start = t0 < t1 ? t0 : t1;
    double end = t0 < t1 ? t1 : t0;
    if (start < 0.0) start = 0.0;
    if (end > 1.0) end = 1.0;
    if (start < end) {
      gaps!.add(start);
      gaps!.add(end);
    }
  }

  @override
  void paint(Canvas canvas) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = Scene.poly_edge_thickness.value;
    Offset p1 = Offset(a.sx, a.sy);
    Offset p2 = Offset(b.sx, b.sy);

    paintGappedLine(canvas, p1, p2, paint, gaps);
    dprint("Painting $this: ${zzz(p1)} - ${zzz(p2)}");
  }

  static void paintGappedLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint, List<double>? gaps) {
    if (gaps == null || gaps.isEmpty) {
      canvas.drawLine(p1, p2, paint);
      return;
    }

    List<List<double>> intervals = [];
    for (int i = 0; i < gaps.length; i += 2) {
      intervals.add([gaps[i], gaps[i + 1]]);
    }
    intervals.sort((i1, i2) => i1[0].compareTo(i2[0]));

    List<List<double>> merged = [];
    for (var interval in intervals) {
      if (merged.isEmpty) {
        merged.add(interval);
      } else {
        var last = merged.last;
        if (interval[0] <= last[1]) {
          if (interval[1] > last[1]) {
            last[1] = interval[1];
          }
        } else {
          merged.add(interval);
        }
      }
    }

    double currentT = 0.0;
    for (var g in merged) {
      double gStart = g[0];
      double gEnd = g[1];
      if (gStart > currentT) {
        Offset segStart = Offset.lerp(p1, p2, currentT)!;
        Offset segEnd = Offset.lerp(p1, p2, gStart)!;
        canvas.drawLine(segStart, segEnd, paint);
      }
      if (gEnd > currentT) {
        currentT = gEnd;
      }
    }
    if (currentT < 1.0) {
      Offset segStart = Offset.lerp(p1, p2, currentT)!;
      Offset segEnd = p2;
      canvas.drawLine(segStart, segEnd, paint);
    }
  }

  @override
  String toString() {
    return "Seg $a-$b";
  }

  @override
  void dumpDebugInfo() {
    print("  LineSegment $a to $b (gaps: $gaps)");
  }
}
