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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polytope/main.dart';
import 'package:polytope/scene.dart';
import 'package:polytope/settings.dart';
import 'package:polytope/widget.dart';
import 'package:polytope/xr_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Settings.isAndroidTvOverride = null;
    Settings.testInitialValues = {};
    Settings.instance.is_android_tv = false;
    Settings.instance.status = SettingsStatus.NotInitialized;
    Settings.instance.savables.clear();
    PolyAppWidgetState.initSettings(Settings.instance);
    Scene.show_pan_zoom_buttons.value = false;
  });

  tearDown(() {
    Settings.isAndroidTvOverride = null;
    Settings.testInitialValues = null;
    Settings.instance.is_android_tv = false;
    Settings.instance.status = SettingsStatus.NotInitialized;
    Scene.show_pan_zoom_buttons.value = false;
  });

  group('Pan/Zoom Controls', () {
    testWidgets('Defaults to off on non-TV and on for Android TV',
        (WidgetTester tester) async {
      Settings.isAndroidTvOverride = false;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      expect(Scene.show_pan_zoom_buttons.value, isFalse);
      expect(find.byTooltip('Up'), findsNothing);

      // Now simulate Android TV with no saved preference.
      Settings.isAndroidTvOverride = true;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      Settings.instance.is_android_tv = false;
      Settings.instance.status = SettingsStatus.NotInitialized;
      Settings.instance.savables.clear();
      PolyAppWidgetState.initSettings(Settings.instance);
      final tvBuilder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(tvBuilder.makeApp());
      await tester.pumpAndSettle();

      expect(Scene.show_pan_zoom_buttons.value, isTrue);
      expect(find.byTooltip('Up'), findsOneWidget);
      expect(find.byTooltip('Down'), findsOneWidget);
      expect(find.byTooltip('Left'), findsOneWidget);
      expect(find.byTooltip('Right'), findsOneWidget);
      expect(find.byTooltip('Stop Spin'), findsOneWidget);
      expect(find.byTooltip('Zoom In'), findsOneWidget);
      expect(find.byTooltip('Zoom Out'), findsOneWidget);
    });

    testWidgets('Android TV respects saved false preference',
        (WidgetTester tester) async {
      Settings.testInitialValues = {'show_pan_zoom_buttons': false};
      Settings.isAndroidTvOverride = true;

      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      expect(Scene.show_pan_zoom_buttons.value, isFalse);
      expect(find.byTooltip('Up'), findsNothing);
    });

    testWidgets('Buttons trigger current movement tool and zoom',
        (WidgetTester tester) async {
      Settings.isAndroidTvOverride = true;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      final state =
          tester.state<PolyAppWidgetState>(find.byType(PolyAppWidget));
      final scene = state.scene;

      // Test Zoom In / Zoom Out buttons.
      final initialZoom = scene.transform.zoom;
      await tester.tap(find.byTooltip('Zoom In'));
      await tester.pump();
      expect(scene.transform.zoom, greaterThan(initialZoom));

      await tester.tap(find.byTooltip('Zoom Out'));
      await tester.pump();
      expect(scene.transform.zoom, closeTo(initialZoom, 1e-6));

      // Test Translate mode with directional buttons.
      scene.movement = CameraMovement.translate;
      final initialOffset = scene.transform.offset.clone();
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      expect(scene.transform.offset.x, greaterThan(initialOffset.x));

      await tester.tap(find.byTooltip('Up'));
      await tester.pump();
      expect(scene.transform.offset.y, lessThan(initialOffset.y));

      // Test Rotate R3 mode with directional buttons.
      scene.movement = CameraMovement.rotate3;
      final beforeRotate = scene.transform.A[0][2];
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      expect(scene.transform.A[0][2], isNot(equals(beforeRotate)));
    });

    testWidgets('Keyboard shortcuts pan/rotate and zoom',
        (WidgetTester tester) async {
      Settings.instance.status = SettingsStatus.Initialized;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      final state =
          tester.state<PolyAppWidgetState>(find.byType(PolyAppWidget));
      final scene = state.scene;

      // Zoom in with bracketRight, zoom out with bracketLeft.
      final initialZoom = scene.transform.zoom;
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
      await tester.pump();
      expect(scene.transform.zoom, greaterThan(initialZoom));

      await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
      await tester.pump();
      expect(scene.transform.zoom, closeTo(initialZoom, 1e-6));

      // Translate with arrow keys.
      scene.movement = CameraMovement.translate;
      final initialOffset = scene.transform.offset.clone();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(scene.transform.offset.x, greaterThan(initialOffset.x));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(scene.transform.offset.y, greaterThan(initialOffset.y));
    });

    testWidgets(
        'Double clicking rotate buttons adds spin and stop button halts it',
        (WidgetTester tester) async {
      Settings.isAndroidTvOverride = true;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      final state =
          tester.state<PolyAppWidgetState>(find.byType(PolyAppWidget));
      final scene = state.scene;
      var fakeTime = DateTime(2026, 1, 1, 12, 0, 0);
      scene.clockNow = () => fakeTime;

      // Double clicking in translate mode does not start spin.
      scene.movement = CameraMovement.translate;
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      fakeTime = fakeTime.add(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      expect(scene.transform.speed[0], equals(0.0));
      expect(scene.transform.speed[1], equals(0.0));

      // Single tap in rotate3 does not start spin.
      scene.movement = CameraMovement.rotate3;
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      expect(scene.transform.speed[0], equals(0.0));

      // Tapping again after > 300ms does not start spin.
      fakeTime = fakeTime.add(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      expect(scene.transform.speed[0], equals(0.0));

      // Double clicking Right (< 300ms) starts positive x spin.
      fakeTime = fakeTime.add(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      final firstSpeed = scene.transform.speed[0];
      expect(firstSpeed, greaterThan(0.0));

      // Second double-click Right increases spin further.
      fakeTime = fakeTime.add(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      fakeTime = fakeTime.add(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Right'));
      await tester.pump();
      expect(scene.transform.speed[0], closeTo(firstSpeed * 2, 1e-6));

      // Double clicking Left reduces spin back down.
      fakeTime = fakeTime.add(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Left'));
      await tester.pump();
      fakeTime = fakeTime.add(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Left'));
      await tester.pump();
      expect(scene.transform.speed[0], closeTo(firstSpeed, 1e-6));

      // Double clicking Up adds vertical spin.
      fakeTime = fakeTime.add(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Up'));
      await tester.pump();
      fakeTime = fakeTime.add(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Up'));
      await tester.pump();
      expect(scene.transform.speed[1], greaterThan(0.0));

      // Tapping Stop Spin resets both spin components to zero.
      await tester.tap(find.byTooltip('Stop Spin'));
      await tester.pump();
      expect(scene.transform.speed[0], equals(0.0));
      expect(scene.transform.speed[1], equals(0.0));
    });

    testWidgets(
        'Android TV disables canvas focus trap, hides hotkeys, and allows D-pad navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Settings.isAndroidTvOverride = true;
      Settings.instance.no_keyboard = true;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      final state =
          tester.state<PolyAppWidgetState>(find.byType(PolyAppWidget));
      final scene = state.scene;

      // Hotkey buttons default to off on Android TV even when no_keyboard is true.
      expect(Scene.show_hotkey_buttons.value, isFalse);

      // Canvas does not steal or trap focus on Android TV.
      expect(scene.canvasFocusNode.hasFocus, isFalse);
      expect(scene.canvasFocusNode.canRequestFocus, isFalse);

      // Initial focus lands on the Stop Spin button; D-pad Right moves focus
      // to the Right button and Enter activates it.
      final initialFocus = FocusManager.instance.primaryFocus;
      expect(initialFocus, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      final afterRightFocus = FocusManager.instance.primaryFocus;
      expect(afterRightFocus, isNot(equals(initialFocus)));

      scene.movement = CameraMovement.translate;
      final initialOffset = scene.transform.offset.clone();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(scene.transform.offset.x, greaterThan(initialOffset.x));
    });

    testWidgets(
        'Settings sliders use Left/Right for value and Up/Down for focus traversal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Settings.isAndroidTvOverride = true;
      Settings.instance.is_android_tv = true;
      Settings.instance.status = SettingsStatus.Initialized;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      // Open SettingsScreen.
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      // Focus the first Slider row (Polytope Edge Thickness).
      final firstSliderFocus = find.ancestor(
        of: sliders.first,
        matching: find.byWidgetPredicate(
          (w) => w is Focus && w.focusNode?.debugLabel == 'SettingsSlider',
        ),
      );
      final sliderFocusNode =
          tester.widget<Focus>(firstSliderFocus.first).focusNode!;
      sliderFocusNode.requestFocus();
      await tester.pump();
      expect(sliderFocusNode.hasFocus, isTrue);

      final initialVal = Scene.poly_edge_thickness.value;

      // On Android TV, Arrow Right does NOT change value until Select enters edit mode.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(Scene.poly_edge_thickness.value, equals(initialVal));

      // Re-focus if arrowRight moved focus, then press Enter to enter edit mode.
      sliderFocusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Now Arrow Right adjusts the slider value.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(Scene.poly_edge_thickness.value, greaterThan(initialVal));
      expect(sliderFocusNode.hasFocus, isTrue);

      // Pressing Enter exits edit mode so Arrow Right no longer changes value.
      final valAfterEdit = Scene.poly_edge_thickness.value;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(Scene.poly_edge_thickness.value, equals(valAfterEdit));

      // Re-focus and verify Arrow Down moves focus to the next row.
      sliderFocusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(Scene.poly_edge_thickness.value, equals(valAfterEdit));
      expect(sliderFocusNode.hasFocus, isFalse);
    });

    testWidgets(
        'Android TV polytope menu autofocuses inside menu and TV color picker responds to D-pad',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Settings.isAndroidTvOverride = true;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      final state =
          tester.state<PolyAppWidgetState>(find.byType(PolyAppWidget));
      expect(state.scene.type.name, equals('Simplex'));

      // Open the Polytope menu (Simplex) and press Down + Enter to pick Cube.
      await tester.tap(find.text('Simplex'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(state.scene.type.name, equals('Cube'));

      // Open Settings and activate Polytope Color to open TV color dialog.
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      final beforeColor = Scene.poly_color.value;
      await tester.tap(find.text('Polytope Color'));
      await tester.pumpAndSettle();

      // Move right in swatch grid and press Enter to pick a different color.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(Scene.poly_color.value, isNot(equals(beforeColor)));
    });

    testWidgets(
        'Slice slider Select toggles forward animation without stopping rotation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Settings.isAndroidTvOverride = true;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      final state =
          tester.state<PolyAppWidgetState>(find.byType(PolyAppWidget));
      final scene = state.scene;
      // Enable slice and start rotation spin.
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(scene.slice, isNotNull);

      scene.transform.setSpeed(50.0, 0.0);
      final expectedSpinSpeed = scene.transform.speed[0];
      expect(expectedSpinSpeed, greaterThan(0.0));
      final slider = scene.slice!.slider;
      slider.setSpeed(0.0);
      expect(slider.speed, equals(0.0));

      // Focus the slider track Focus widget (ancestor of CustomPaint with SliderPainter).
      final sliderPaintFinder = find.byWidgetPredicate((w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == 'SliderPainter');
      final sliderFocusNode = Focus.of(tester.element(sliderPaintFinder.first));
      expect(sliderFocusNode.debugLabel, equals('SliceSliderTrack'));
      sliderFocusNode.requestFocus();
      await tester.pump();
      expect(sliderFocusNode.hasPrimaryFocus, isTrue);

      // Space/Enter starts forward animation without stopping rotation.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(slider.speed, greaterThan(0.0),
          reason:
              'speed=${slider.speed} val=${slider.value} min=${slider.min} max=${slider.max} allow=${slider.allow_animate}');
      expect(scene.transform.speed[0], equals(expectedSpinSpeed));

      // Pressing Space again stops slider without stopping rotation.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(slider.speed, equals(0.0));
      expect(scene.transform.speed[0], equals(expectedSpinSpeed));

      // RotationSnap preserves active slice slider speed.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final activeSliderSpeed = slider.speed;
      expect(activeSliderSpeed, greaterThan(0.0));
      RotationSnap.vertex.snap(scene);
      expect(scene.slice!.slider.speed, closeTo(activeSliderSpeed, 1e-6));

      // Moving Up from slice slider focuses the rotation buttons.
      sliderFocusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(scene.panZoomCenterFocusNode.hasPrimaryFocus, isTrue);

      // Moving Down from any AppBar toolbar button (e.g. Help) focuses rotation buttons.
      final helpNode = Focus.of(tester.element(find.byIcon(Icons.help)));
      helpNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(scene.panZoomCenterFocusNode.hasPrimaryFocus, isTrue);
    });

    testWidgets(
        'Active rotation mode via long-press on center button spins on tap, rotates on hold, stops on tap, exits on long-press or Back',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Settings.isAndroidTvOverride = true;
      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      final state =
          tester.state<PolyAppWidgetState>(find.byType(PolyAppWidget));
      final scene = state.scene;
      expect(scene.activeRotationMode, isFalse);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.public), findsNothing);
      expect(scene.panZoomCenterFocusNode.hasPrimaryFocus, isTrue);

      // Long-press Enter on center button enters active rotation mode.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 550));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(scene.activeRotationMode, isTrue);
      expect(find.byIcon(Icons.public), findsOneWidget);

      // Tapping Right arrow increases rotation speed in +x direction without moving focus.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      final speed1 = scene.transform.speed[0];
      expect(speed1, greaterThan(0.0));
      expect(scene.panZoomCenterFocusNode.hasPrimaryFocus, isTrue);

      // Tapping center button stops spin while staying in active rotation mode.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(scene.transform.speed[0], equals(0.0));
      expect(scene.activeRotationMode, isTrue);

      // Long-pressing Right arrow steadily rotates while held without adding spin.
      final beforeHoldA02 = scene.transform.A[0][2];
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(scene.transform.A[0][2], isNot(equals(beforeHoldA02)));
      expect(scene.transform.speed[0], equals(0.0));

      // Pressing Escape (Back) leaves active rotation mode.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(scene.activeRotationMode, isFalse);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      // Re-enter via long-press, then exit via second long-press on center button.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 550));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(scene.activeRotationMode, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 550));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(scene.activeRotationMode, isFalse);
    });
  });
}
