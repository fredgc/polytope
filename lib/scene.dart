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
import 'regular.dart';
import 'settings.dart';
import 'slice.dart';
import 'transform.dart';
import 'widget.dart';

class Scene {
  Regular type = Regular.simplex;
  Polytope polytope = Regular.simplex.make(4);
  Slice? slice;
  VoidCallback? startAnimation;
  CoordinateTransform transform = CoordinateTransform();
  ValueNotifier<int> repaint_counter = ValueNotifier<int>(0);
  List<Point> points = [];
  List<Drawable> drawables = [];
  int paint_counter = 0;
  int build_counter = 0;
  KeyStates keys = KeyStates();
  CameraMovement movement = CameraMovement.rotate3;

  Scene() {
    // print("RED: Created new Scene.");
    updateList();
  }

  static SavableColor poly_color = SavableColor("poly_color", "Polytope Color",
      Colors.white, (scheme) => scheme.onSurface);
  static SavableDouble poly_edge_thickness = SavableDouble(
    "poly_edge_thickness",
    "Polytope Edge Thickness",
    2.0,
    min: 0.5,
    max: 10.0,
    divisions: 19,
    tip: "Thickness of polytope edges in pixels",
  );
  static SavableDouble vertex_radius = SavableDouble(
    "vertex_radius",
    "Vertex Size",
    2.0,
    min: 0.5,
    max: 10.0,
    divisions: 19,
    tip: "Radius of vertex dots in pixels",
  );
  static SavableBool enable_line_clipping = SavableBool(
    "enable_line_clipping",
    "Clip Crossing Lines",
    true,
    tip: "Draw gaps when lines cross each other to show depth",
  );
  static SavableDouble clip_gap_size = SavableDouble(
    "clip_gap_size",
    "Clipping Gap Size",
    4.0,
    min: 1.0,
    max: 15.0,
    divisions: 14,
    tip: "Width of gaps drawn when lines cross in pixels",
  );
  static SavableBool show_hotkey_buttons = SavableBool(
      "show_hotkey_buttons", "Show Hotkey Buttons", false,
      tip: "Show buttons on the screen as shortcuts for shift/ctrl/alt.");

  static void initSettings(Settings settings) {
    show_hotkey_buttons.value = settings.no_keyboard;
    settings.add(poly_color);
    settings.add(poly_edge_thickness);
    settings.add(vertex_radius);
    settings.add(EndOfRow());
    Slice.initSettings(settings);
    settings.add(EndOfRow());
    settings.add(enable_line_clipping);
    settings.add(clip_gap_size);
    settings.add(EndOfRow());
    settings.add(show_hotkey_buttons);
  }

  void setPolytope(Regular type) {
    this.type = type;
    int currentDim = polytope.dim;
    polytope = type.make(currentDim);
    // print("BLUE: set polytope ${type} => ${polytope}");
    // polytope.printAll();
    updateList();
  }

  void setDim(int dim) {
    polytope = type.make(dim);
    // print("BLUE: set dim ${dim} => ${polytope}");
    // polytope.printAll();
    updateList();
  }

  void updateSettings() {
    updateList();
  }

  void updateList() {
    // print("BLUE: Update Scene list. polytope = $polytope");
    slice = null;
    points.clear();
    drawables.clear();
    // Find the lists of vertices and edges.
    for (var p in polytope.vertices) {
      points.add(p.vertex);
      drawables.add(Dot(p, poly_color.value));
    }
    for (var edge in polytope.edges) {
      drawables.add(LineSegment(edge, poly_color.value));
    }
    // Reset the transform.
    transform = CoordinateTransform();
    updateScene();
    dprint("After update list. repaint counter = $repaint_counter");
  }

  void paint(Canvas canvas, Size size) {
    dprint("BLUE: paint.");
    if (transform.sizeChanged(size)) {
      transform.resize(size);
      updateScene(triggerRepaint: false);
    }
    paint_counter++;
    if (PolyAppWidgetState.debug_logs.value) {
      paintTimeText(canvas, size);
    }
    for (var d in drawables) {
      d.paint(canvas);
    }
  }

  void paintTimeText(Canvas canvas, Size size) {
    final style = TextStyle(
      color: Settings.instance.theme.scheme.onSurface,
      fontSize: 10.0,
    );
    double t = slice == null ? 0 : slice!.slider.value;
    String text = "t=${zzz(time)}.  "
        "sl=${zzz(t)}, paint=$paint_counter/${repaint_counter.value}, "
        "build=$build_counter #=${drawables.length}";
    var span = TextSpan(text: text, style: style);
    var painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    painter.layout();
    Offset offset = Offset(
        size.width - painter.width - 5, size.height - painter.height - 5);
    painter.paint(canvas, offset);
  }

  String debugPrint() {
    String s = slice == null ? "" : slice!.debugPrint();
    return "${s}sc(r${repaint_counter.value}p$paint_counter,b$build_counter) $polytope";
  }

  void dumpDebugInfo() {
    print("GREEN: ---- dumping debug info -----");
    polytope.printConcise();
    // polytope.printAll();
    transform.dumpDebugInfo();
    slice?.dumpDebugInfo();
    print("Points:");
    for (var p in points) {
      print("  ${zzz(p)} -> (${zzz(p.sx)}, ${zzz(p.sy)}, ${zzz(p.sz)})");
    }
    print("Drawables:");
    for (var d in drawables) {
      d.dumpDebugInfo();
    }
  }

  bool get slice_active => (slice != null);

  void changeSlice(bool active) {
    if (!active) {
      slice = null;
      updateList();
    } else {
      slice = Slice(polytope, points, drawables, () {
        // print("BLUE: Scene heard startAnimation.");
        startAnimation?.call();
        updateScene();
      });
      slice!.addListener(updateScene);
      updateScene();
    }
  }

  double time = 0.0; //Just for debugging.
  bool updateTime(double dt) {
    dprint("BLUE: updateTime.");
    time += dt;
    bool changed = transform.updateTime(dt);
    if (slice != null) {
      changed |= slice!.updateTime(dt);
    }
    if (changed) updateScene();
    return changed;
  }

  void clipLines() {
    // Reset gaps on all ClippableEdges.
    for (var d in drawables) {
      if (d is ClippableEdge) {
        d.resetGaps();
      }
    }

    if (!enable_line_clipping.value) {
      return;
    }

    // Collect ClippableEdges that are visible.
    List<ClippableEdge> segments = [];
    for (var d in drawables) {
      if (d is ClippableEdge && d.isEdgeVisible) {
        segments.add(d);
      }
    }

    final double gapPx = clip_gap_size.value;
    final int n = segments.length;
    for (int i = 0; i < n; i++) {
      ClippableEdge s1 = segments[i];
      double x1 = s1.ptA.sx, y1 = s1.ptA.sy;
      double x2 = s1.ptB.sx, y2 = s1.ptB.sy;
      double dx1 = x2 - x1, dy1 = y2 - y1;
      double len1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
      if (len1 < 1e-4) continue;

      for (int j = i + 1; j < n; j++) {
        ClippableEdge s2 = segments[j];
        // Skip lines that share a vertex (they meet at endpoints).
        if (identical(s1.ptA, s2.ptA) ||
            identical(s1.ptA, s2.ptB) ||
            identical(s1.ptB, s2.ptA) ||
            identical(s1.ptB, s2.ptB)) {
          continue;
        }

        // Also check if a SlideEdge ends at a Polytope edge (sourceEdge)
        // or connects to a vertex of s1 / s2.
        if (s1 is SlideEdge && s2 is LineSegment) {
          if (_slideDotOnEdge(s1.a, s2) || _slideDotOnEdge(s1.b, s2)) {
            continue;
          }
        } else if (s2 is SlideEdge && s1 is LineSegment) {
          if (_slideDotOnEdge(s2.a, s1) || _slideDotOnEdge(s2.b, s1)) {
            continue;
          }
        }

        double x3 = s2.ptA.sx, y3 = s2.ptA.sy;
        double x4 = s2.ptB.sx, y4 = s2.ptB.sy;
        double dx2 = x4 - x3, dy2 = y4 - y3;
        double len2 = math.sqrt(dx2 * dx2 + dy2 * dy2);
        if (len2 < 1e-4) continue;

        // Check bounding box overlap first.
        double minX1 = x1 < x2 ? x1 : x2, maxX1 = x1 < x2 ? x2 : x1;
        double minY1 = y1 < y2 ? y1 : y2, maxY1 = y1 < y2 ? y2 : y1;
        double minX2 = x3 < x4 ? x3 : x4, maxX2 = x3 < x4 ? x4 : x3;
        double minY2 = y3 < y4 ? y3 : y4, maxY2 = y3 < y4 ? y4 : y3;

        if (maxX1 < minX2 || minX1 > maxX2 || maxY1 < minY2 || minY1 > maxY2) {
          continue;
        }

        // 2D line segment intersection.
        // P1 + t1 * (P2 - P1) == P3 + t2 * (P4 - P3)
        double denom = dx1 * dy2 - dy1 * dx2;
        if (denom.abs() < 1e-6) continue; // Parallel or collinear.

        double dx31 = x3 - x1;
        double dy31 = y3 - y1;
        double t1 = (dx31 * dy2 - dy31 * dx2) / denom;
        double t2 = (dx31 * dy1 - dy31 * dx1) / denom;

        // Interior intersection (avoid clipping near endpoints).
        const double eps = 0.02;
        if (t1 > eps && t1 < 1.0 - eps && t2 > eps && t2 < 1.0 - eps) {
          // Compare Z depths at the crossing point.
          // In transform.dart: p.sz = zoom * temp.x[2], where higher sz is closer.
          double z1 = s1.ptA.sz + t1 * (s1.ptB.sz - s1.ptA.sz);
          double z2 = s2.ptA.sz + t2 * (s2.ptB.sz - s2.ptA.sz);

          if ((z1 - z2).abs() < 1e-3) {
            // Depths are virtually identical.
            continue;
          }

          if (z1 < z2) {
            // s1 is behind s2; gap on s1.
            double dt1 = gapPx / len1;
            s1.addGap(t1 - dt1, t1 + dt1);
          } else {
            // s2 is behind s1; gap on s2.
            double dt2 = gapPx / len2;
            s2.addGap(t2 - dt2, t2 + dt2);
          }
        }
      }
    }
  }

  static bool _slideDotOnEdge(SlideDot dot, LineSegment line) {
    // A SlideDot moves along the polytope edge between dot.a and dot.b.
    // If line has the same edge endpoints, dot ends at line.
    Vertex? v1 = line.vertexA;
    Vertex? v2 = line.vertexB;
    if (v1 == null || v2 == null) return false;
    return (dot.a == v1 && dot.b == v2) || (dot.a == v2 && dot.b == v1);
  }

  void updateScene({bool triggerRepaint = true}) {
    dprint("BLUE: updateScene.");
    if (slice != null) {
      slice!.computeSlice();
    }
    transform.apply(points);
    clipLines();
    if (triggerRepaint) repaint_counter.value++;
  }

  void dispose() {}

  Widget build(BuildContext context, State state) {
    // print("ORANGE: build scene.");
    build_counter++;
    Widget main = Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            onScrollWheel(pointerSignal);
          }
        },
        child: GestureDetector(
            onScaleStart: scaleStart,
            onScaleUpdate: scaleUpdate,
            onScaleEnd: scaleEnd,
            onTapUp: tapUp,
            child: CustomPaint(
              painter: ScenePainter(scene: this, repaint: repaint_counter),
              child: Container(),
              // XXX If we want background painting:
              // foregroundPainter:
              //     ScenePainter(scene: this, repaint: repaint_counter),
              // painter: AxisPainter(
              //   transform, settings.axis_color.color, x_axis, y_axis),
            )));
    if (!show_hotkey_buttons.value) {
      return main;
    }
    Widget inset = keys.hotKeyButtons(
        context, () => state.setState(() => updateMovement()));
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: <Widget>[main, inset],
    );
  }

  Tooltip makeTip(String tip, String hotkey, Widget child) {
    return Tooltip(
      richMessage: TextSpan(
        text: tip,
        children: <InlineSpan>[
          TextSpan(
            text: " key(",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: hotkey,
            style: TextStyle(
                fontFamily: "monospace",
                fontFamilyFallback: <String>["Courier"]),
          ),
          TextSpan(
            text: ")",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      preferBelow: true,
      waitDuration: Duration(seconds: 2),
      child: child,
    );
  }

  Widget buildMovementMenu(BuildContext context, State state) {
    var movements = CameraMovement.values
        .where((item) => (item.dim < polytope.dim))
        .map((item) => MenuItemButton(
              child: makeTip(item.tip, item.hotkeys, Text(item.name)),
              onPressed: () {
                if (item != movement) {
                  state.setState(() {
                    movement = item;
                  });
                }
              },
            ))
        .toList();
    var snaps = RotationSnap.values
        .where((item) => (item.dim < polytope.dim))
        .map((item) => MenuItemButton(
              child: makeTip(item.tip, item.character, Text(item.name)),
              onPressed: () {
                // print("Menu $item");
                state.setState(() {
                  item.snap(this);
                });
              },
            ))
        .toList();

    return MenuAnchor(
        menuChildren: movements + snaps,
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return Tooltip(
              message: movement.tip,
              waitDuration: Duration(seconds: 2),
              child: TextButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: Text(movement.name),
              ));
        });
  }

  void updateMovement() {
    String hotkeys = keys.hotkeys();
    // print("Hotkeys = $hotkeys");
    for (var item in CameraMovement.values) {
      if (item.hotkeys == hotkeys && item.dim < polytope.dim) {
        movement = item;
        // print("Movement is now $movement");
      }
    }
  }

  bool keyHandle(String? character) {
    // print("Key Handle: character = $character");
    for (var snap in RotationSnap.values) {
      if (snap.character == character && snap.dim < polytope.dim) {
        // print("Doing a snap $snap");
        snap.snap(this);
        return true;
      }
    }
    bool changed = keys.update();
    if (changed) {
      updateMovement();
    }
    if (character == " ") {
      dprint("Character Space. Pause.");
      stopMovement();
    }
    if (character == "-") {
      dprint("slow.");
      slice?.slider.incrementSpeed(-1);
    }
    if ((character == "=") || (character == "+")) {
      dprint("fast.");
      slice?.slider.incrementSpeed(1);
    }
    return changed;
  }

  void onScrollWheel(PointerScrollEvent event) {
    double delta = event.scrollDelta.dx - event.scrollDelta.dy;
    // Delta is sort-of in screen coordinates.
    double scale = math.exp(delta / 1000.0);
    transform.scaleBy(scale);
    updateScene();
  }

  bool scale_start = true;
  double previous_rotate = 0.0;
  double previous_scale = 1.0;
  void scaleStart(ScaleStartDetails info) {
    scale_start = true;
    // XXX -- maybe if doing rotation? transform.setSpeed(0.0, 0.0);
    // print("Scale start, movement = ${movement}");
  }

  void scaleUpdate(ScaleUpdateDetails info) {
    if (scale_start) {
      previous_rotate = info.rotation;
      previous_scale = info.scale;
      scale_start = false;
    }
    // For some reason, update does not give us a delta.
    double dtheta = info.rotation - previous_rotate;
    previous_rotate = info.rotation;
    double dscale = info.scale / previous_scale;
    previous_scale = info.scale;
    transform.scaleBy(dscale);
    switch (movement) {
      case CameraMovement.rotate3:
      case CameraMovement.rotate4:
      case CameraMovement.rotate5:
        transform.rotatePair(
            movement.dim, info.focalPointDelta.dx, info.focalPointDelta.dy);
        break;
      case CameraMovement.zolly:
        transform.zollyBy(2, info.focalPointDelta.dx);
        transform.zollyBy(3, info.focalPointDelta.dy);
        break;
      case CameraMovement.translate:
        transform.pan(info.focalPointDelta.dx, info.focalPointDelta.dy);
        break;
      case CameraMovement.scale:
        double delta = (info.focalPointDelta.dx / transform.size.width -
            info.focalPointDelta.dy / transform.size.height);
        transform.scaleBy(1.0 + delta);
        break;
    }
    transform.rotate(0, 1, dtheta);
    updateScene();
  }

  void scaleEnd(ScaleEndDetails info) {
    if (movement != CameraMovement.rotate3) {
      dprint("Animation only done in R3.");
      return;
    }
    dprint("Scale end: $info");
    var v = info.velocity.pixelsPerSecond;
    // Slow it down a bit:
    double scale = 0.2;
    transform.setSpeed(v.dx * scale, v.dy * scale);
    startAnimation?.call();
  }

  void tapUp(TapUpDetails info) {
    dprint("TapUp pos ${zzz(info.localPosition)}.");
    // Stop rotations, but not slice.
    transform.setSpeed(0.0, 0.0);
  }

  void stopMovement() {
    dprint("Stop movement.");
    transform.setSpeed(0.0, 0.0);
    slice?.slider.setSpeed(0.0);
  }
}

/* Keep track of the current UI choices. There are a pair of choices:
   rotate, translate, or zolly;
   and R3, R4, or R5.

   If the user changes the menu, then the choice is updated. If the user presses
   a modifier key (shift, alt,ctrl) then the choice is also updated:
   press shift -> R4. release shift -> R3.
   ctrl -> zolly, alt -> translate
   release ctrl/alt -> rotate
*/
enum CameraMovement {
  rotate3("Rotate R3", 2, "...", "Mouse drags will rotate the polytope in R3"),
  rotate4("Rotate R4", 3, "S..", "Mouse drags will rotate the polytope in R4"),
  rotate5("Rotate R5", 4, "SC.", "Mouse drags will rotate the polytope in R5"),
  zolly("Zolly", 0, ".C.",
      "Zolly = zoom + dolly. Mouse drags will change the perspective."),
  translate(
      "Translate", 0, "..A", "Mouse drags will move or translate the polytope"),
  scale("Scale", 0, ".CA",
      "Mouse drags will make the polytope larger or smaller");

  const CameraMovement(this.name, this.dim, this.hotkeys, this.tip);
  final String name;
  final String tip;
  final int dim;
  final String hotkeys;
  @override
  String toString() => name;
}

enum RotationSnap {
  vertex("Vertex first", 0, "0", "Rotate polytope so a vertex is in front"),
  edge("Edge first", 1, "1", "Rotate polytope so an edge is in front"),
  face("Face first", 2, "2", "Rotate polytope so a face is in front"),
  cell("3-Cell first", 3, "3", "Rotate polytope so a 3-cell is in front");

  const RotationSnap(this.name, this.dim, this.character, this.tip);
  final String name;
  final String tip;
  final int dim;
  final String character;
  @override
  String toString() => name;
  void snap(Scene scene) {
    scene.transform.resetRotation();
    // rotate so that the cell points in the direction most away from the
    // screen. i.e. in Dim 3, point in z axis. In Dim 4 point in w axis.
    scene.polytope.cellFirst(dim);
    if (scene.slice != null) {
      double value = scene.slice!.slider.value;
      scene.changeSlice(false); //Remove old slice...
      scene.changeSlice(true); //and add new one.
      scene.slice!.slider.value = value;
    } else {
      scene.updateScene();
    }
  }
}

class UpdatableBool {
  bool value = false;

  bool update(bool v) {
    if (value == v) return false;
    value = v;
    return true;
  }
}

// Tracks keyboard state. To modify mouse actions.
class KeyStates {
  UpdatableBool isShiftPressed = UpdatableBool();
  UpdatableBool isControlPressed = UpdatableBool();
  UpdatableBool isAltPressed = UpdatableBool();

  bool update() {
    return (isShiftPressed.update(HardwareKeyboard.instance.isShiftPressed) ||
        isControlPressed.update(HardwareKeyboard.instance.isControlPressed) ||
        isAltPressed.update(HardwareKeyboard.instance.isAltPressed));
  }

  String hotkeys() {
    return ((isShiftPressed.value ? "S" : ".") +
        (isControlPressed.value ? "C" : ".") +
        (isAltPressed.value ? "A" : "."));
  }

  Widget hotKeyButtons(BuildContext context, VoidCallback callback) {
    return Row(children: <Widget>[
      hotkeyButton("S", isShiftPressed, callback, context),
      hotkeyButton("C", isControlPressed, callback, context),
      hotkeyButton("A", isAltPressed, callback, context),
    ]);
  }

  Widget hotkeyButton(String name, UpdatableBool value, VoidCallback callback,
      BuildContext context) {
    ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
        child: GestureDetector(
      onScaleStart: (info) => hotkeyStart(name, value, callback),
      // onScaleUpdate: (info) => hotkeyUpdate(name),
      onScaleEnd: (info) => hotkeyEnd(name, value, callback),
      onTapDown: (info) => hotkeyStart(name, value, callback),
      onTapUp: (info) => hotkeyEnd(name, value, callback),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: value.value ? scheme.primary : scheme.inversePrimary,
        child: Text(name,
            style: TextStyle(
                color:
                    value.value ? scheme.onPrimary : scheme.onInverseSurface)),
      ),
    ));
  }

  void hotkeyStart(String s, UpdatableBool value, VoidCallback callback) {
    value.update(true);
    callback.call();
    dprint("Start hotkey $s");
  }

  void hotkeyEnd(String s, UpdatableBool value, VoidCallback callback) {
    value.update(false);
    callback.call();
    dprint("Start hotkey $s");
  }
}

class ScenePainter extends CustomPainter {
  Scene scene;
  ScenePainter({required this.scene, repaint}) : super(repaint: repaint);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    bool should = (this != oldDelegate);
    return should;
  }

  @override
  void paint(Canvas canvas, Size size) {
    scene.paint(canvas, size);
  }
}
