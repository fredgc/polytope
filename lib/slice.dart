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

import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import "drawable.dart";
import "printer.dart";
import "vector.dart";
import 'color.dart';
import 'polytope.dart';
import 'settings.dart';
import 'slider.dart';
import 'transform.dart';

class Slice with ChangeNotifier {
  MySlider slider = MySlider("Slice", -1.5, 1.5, -1.5);
  List<Intersection> intersections = [];

  static final double tolerance = 1e-6;
  static SavableColor slice_color = SavableColor("slice_color", "Slice Color",
      Colors.yellow, (scheme) => scheme.inversePrimary);

  static void initSettings(Settings settings) {
    settings.add(slice_color);
  }

  // The list points is transformed by the scene when the rotation matrix is update.
  // The list of drawables are drawn by the scene.
  Slice(Polytope polytope, List<Point> points, List<Drawable> drawables,
      VoidCallback startAnimation) {
    slider.startAnimation = startAnimation;
    slider.addListener(onSliderChanged);
    Vector direction = Vector.unit(polytope.dim - 1);
    Map<Polytope, Intersection> map = Map();
    List<double> transitions = [];
    // Each vertex is a singular slide dot.
    for (var p in polytope.vertices) {
      Intersection dot = SingularDot(p, direction, slice_color.value);
      drawables.add(dot);
      map[p] = dot;
      intersections.add(dot);
      transitions.add(dot.min);
    }
    for (var edge in polytope.edges) {
      Intersection sl = sliceEdge(map, points, edge, direction);
      drawables.add(sl);
      intersections.add(sl);
      map[edge] = sl;
    }
    for (var face in polytope.faces) {
      sliceFace(map, drawables, face, direction);
    }
    slider.addSticky(transitions);
    slider.autoRange();
    computeSlice();
  }

  // Slice an edge with a hyperplace to get either a slide dot, or a a singular
  // slide edge.
  Intersection sliceEdge(Map<Polytope, Intersection> map, List<Point> points,
      Polytope edge, Vector direction) {
    assert(edge.cells.length == 2);
    Vertex a = edge.cells.elementAt(0) as Vertex;
    Vertex b = edge.cells.elementAt(1) as Vertex;
    // The two vertices have already been turned into singular slide dots.
    SingularDot da = map[a] as SingularDot;
    SingularDot db = map[b] as SingularDot;
    if ((da.min - db.min).abs() < Slice.tolerance) {
      // If these two have the same position, then this is a singular edge.
      return SingularEdge(da, db, slice_color.value);
    }
    // Otherwise, this is a nonsingular slide dot.
    SlideDot dot = SlideDot(a, b, direction, slice_color.value);
    points.add(dot);
    return dot;
  }

  // Slice a polygon face.
  void sliceFace(Map<Polytope, Intersection> map, List<Drawable> drawables,
      Polytope face, Vector direction) {
    List<SlideDot> dots = [];
    // Get a list of all the dots.
    for (var edge in face.cells) {
      Intersection? i = map[edge];
      // If edge is singular, then skip it because we already added it to
      // the list of interections and drawables. If not, it made a slide dot.
      if (i is SlideDot) dots.add(i as SlideDot);
    }
    dprint("Face $face has ${dots.length} non-singular edges.");
    // Since the face is convex and regular, the hyperplane can only intersect
    // two non singular edges at a time.
    for (int i = 0; i < dots.length; i++) {
      for (int j = i + 1; j < dots.length; j++) {
        bool dont_intersect =
            ((dots[i].max <= dots[j].min) || (dots[i].min >= dots[j].max));
        if (dont_intersect) {
          dprint("  Edge $i and $j don't intersect");
        } else {
          dprint("  Edge $i and $j intersect");
        }
        if (!dont_intersect) {
          SlideEdge edge = SlideEdge(dots[i], dots[j], slice_color.value);
          drawables.add(edge);
          intersections.add(edge);
        }
      }
    }
  }

  void computeSlice() {
    for (Intersection obj in intersections) {
      obj.updatePosition(slider.value);
    }
  }

  String debugPrint() {
    return slider.debugPrint();
  }

  void dumpDebugInfo() {
    print("Slider ${zzz(slider.value)} in " +
        "[${zzz(slider.min)}..${zzz(slider.max)}]" +
        ", sticky = ${zzz(slider.sticky)}");
    for (var i in intersections) {
      i.dumpDebugInfo();
    }
  }

  bool updateTime(double dt) {
    dprint("BLUE: update slice time.");
    bool changed = slider.updateTime(dt, notifyOnChange: false);
    if (changed) computeSlice();
    return changed;
  }

  // This is called when the slider value changes through the ui.
  void onSliderChanged() {
    // XXX Debug.print_debug = 1;
    computeSlice();
    notifyListeners();
  }
}

// An intersection of a polytope with a hyperplane.
mixin Intersection implements Drawable {
  double min = 0.0; // The minimum height at which this is visible
  double max = 0.0; // The maximum height at which this is visible.
  bool visible = false;

  void updatePosition(double t);
}

// An intersection of a point with a hyperplace. It is singular in that it is
// contained within the hyperplane only if height = min = max.
class SingularDot with Intersection {
  Vertex pt;
  Vector v = Vector();
  double radius = 2.0;
  Color color;

  static int count = 0;
  int debug_id = count++;
  SingularDot(this.pt, Vector direction, this.color) {
    min = direction.dot(pt.vertex);
    max = min;
    dprint("Made singular dot $this from P${pt}." +
        " R=(${zzz(min)}, ${zzz(max)}.");
  }

  void updatePosition(double t) {
    visible = (t < max + Slice.tolerance) && (t > min - Slice.tolerance);
    dprint("Update $this(v=$visible) -> ${zzz(pt)}");
  }

  void paint(Canvas canvas) {
    if (!visible) return;
    Paint paint = Paint()..color = color;
    Offset c = Offset(pt.vertex.sx, pt.vertex.sy);
    canvas.drawCircle(c, radius, paint);
    dprint("Painting $this, visible = $visible. c=${zzz(c)}");
  }

  String toString() {
    return "SD-$debug_id(${pt})";
  }

  void dumpDebugInfo() {
    print("  Singular $this (v=${zzz(visible)})" +
        " R=(${zzz(min)}, ${zzz(max)}) ${zzz(pt)}");
  }
}

// An intersection that is 0 dimensional. I.e. a point that slides along
// as the height of the hyperplace changes.
class SlideDot extends Point with Intersection {
  Vertex a, b;
  Vector v = Vector();
  double radius = 2.0;
  Color color;

  static int count = 0;
  int debug_id = count++;
  SlideDot(this.a, this.b, Vector direction, this.color)
      : super.from(a.vertex) {
    double t0 = direction.dot(a.vertex);
    double t1 = direction.dot(b.vertex);
    if (t0 <= t1) {
      min = t0;
      max = t1;
    } else {
      min = t1;
      max = t0;
      Vertex temp = a;
      a = b;
      b = temp;
    }
    v = b.vertex - a.vertex;
    dprint("Made slide dot $this from P${a.id} to P${b.id}." +
        " R=(${zzz(min)}, ${zzz(max)}).");
  }

  void updatePosition(double t) {
    visible = (t < max + Slice.tolerance) && (t > min - Slice.tolerance);
    double ratio = (t - min) / (max - min);
    copy(a.vertex);
    add(v * ratio);
    dprint("Update $this(v=$visible) -> ${zzz(this)}");
  }

  void paint(Canvas canvas) {
    if (!visible) return;
    Paint paint = Paint()..color = color;
    Offset c = Offset(sx, sy);
    canvas.drawCircle(c, radius, paint);
    dprint("Painting $this, visible = $visible. c=${zzz(c)}");
  }

  String toString() {
    return "sd-$debug_id(${a.id}-${b.id})";
  }

  void dumpDebugInfo() {
    print("  SlideDot $this (v=${zzz(visible)})" +
        " R=(${zzz(min)}, ${zzz(max)}) ${zzz(this)}");
  }
}

// An intersection of a line segment with a hyperplace. It is singular in that
// it is contained within the hyperplane only if height = min = max.
class SingularEdge with Intersection {
  SingularDot a, b;
  Color color;

  static int count = 0;
  int debug_id = count++;

  SingularEdge(this.a, this.b, this.color) {
    min = a.min; // We assume that b.min = a.min
    max = min;
    dprint("Made slide edge $this from P${a} to P${b}." +
        " R=(${zzz(min)}, ${zzz(max)}).");
  }

  void updatePosition(double t) {
    visible = (t < max + Slice.tolerance) && (t > min - Slice.tolerance);
    dprint("Update $this(v=$visible) -> ${zzz(this)}");
  }

  void paint(Canvas canvas) {
    dprint("Painting $this, visible = $visible");
    if (!visible) return;
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    Offset p1 = Offset(a.pt.vertex.sx, a.pt.vertex.sy);
    Offset p2 = Offset(b.pt.vertex.sx, b.pt.vertex.sy);
    canvas.drawLine(p1, p2, paint);
    dprint("  a = $a =  ${zzz(a)} -> ${zzz(a.pt)}");
    dprint("  b = $b =  ${zzz(b)} -> ${zzz(a.pt)}");
    dprint("  line from ${zzz(p1)} to ${zzz(p2)}");
  }

  String toString() {
    return "SE-$debug_id";
  }

  void dumpDebugInfo() {
    print("  SingEdge $this($a-$b) (v=${zzz(visible)})" +
        " R=(${zzz(min)}, ${zzz(max)})");
  }
}

class SlideEdge with Intersection {
  SlideDot a, b;
  Color color;
  // If the intersection is singular, the original polytope is contained within
  // the hyperplane at height min = max.
  bool singular = false;

  static int count = 0;
  int debug_id = count++;

  SlideEdge(this.a, this.b, this.color) {
    min = math.max(a.min, b.min);
    max = math.min(a.max, b.max);
    if (max - min < Slice.tolerance) singular = true;
    dprint("Made slide edge $this from P${a.debug_id} to P${b.debug_id}." +
        " R=(${zzz(min)}, ${zzz(max)}), singular=${zzz(singular)}.");
  }

  void updatePosition(double t) {
    visible = (t < max + Slice.tolerance) && (t > min - Slice.tolerance);
    dprint("Update $this(v=$visible) -> ${zzz(this)}");
  }

  void paint(Canvas canvas) {
    dprint("Painting $this, visible = $visible");
    if (!visible) return;
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    Offset p1 = Offset(a.sx, a.sy);
    Offset p2 = Offset(b.sx, b.sy);
    canvas.drawLine(p1, p2, paint);
    dprint("  a = $a =  ${zzz(a)} -> ${zzz(p1)}");
    dprint("  b = $b =  ${zzz(b)} -> ${zzz(p2)}");
    dprint("  line from ${zzz(p1)} to ${zzz(p2)}");
  }

  String toString() {
    return "se-$debug_id";
  }

  void dumpDebugInfo() {
    print("  SlideEdge $this($a-$b) (v=${zzz(visible)}, s=${zzz(singular)})" +
        " R=(${zzz(min)}, ${zzz(max)})");
  }
}
