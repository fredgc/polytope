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
import 'package:flutter_test/flutter_test.dart';
import 'package:polytope/l10n/l10n_extension.dart';
import 'package:polytope/main.dart';
import 'package:polytope/scene.dart';
import 'package:polytope/settings.dart';
import 'package:polytope/slice.dart';
import 'package:polytope/widget.dart';
import 'package:polytope/xr_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dark mode theme tests', () {
    testWidgets('PolyAppWidget reflects dark theme',
        (WidgetTester tester) async {
      final settings = Settings.instance;
      PolyAppWidgetState.initSettings(settings);
      settings.theme.theme_mode = ThemeMode.dark;
      settings.theme.update();

      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final expectedSurface = ColorScheme.fromSeed(
        seedColor: settings.theme.theme_color.value,
        brightness: Brightness.dark,
      ).surface;
      final theme = Theme.of(tester.element(scaffoldFinder));
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, expectedSurface);
      expect(theme.scaffoldBackgroundColor, expectedSurface);
    });

    testWidgets('SettingsScreen reflects dark theme',
        (WidgetTester tester) async {
      final settings = Settings.instance;
      PolyAppWidgetState.initSettings(settings);
      settings.status = SettingsStatus.Initialized;
      settings.theme.theme_mode = ThemeMode.dark;
      settings.theme.update();

      await tester.pumpWidget(
        MaterialApp(
          theme: settings.theme.theme_data,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final expectedSurface = ColorScheme.fromSeed(
        seedColor: settings.theme.theme_color.value,
        brightness: Brightness.dark,
      ).surface;
      final theme = Theme.of(tester.element(scaffoldFinder));
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, expectedSurface);
      expect(theme.scaffoldBackgroundColor, expectedSurface);

      final buttonStyle = theme.elevatedButtonTheme.style!;
      expect(
        buttonStyle.backgroundColor?.resolve({}),
        theme.colorScheme.primaryContainer,
      );
      expect(
        buttonStyle.foregroundColor?.resolve({}),
        theme.colorScheme.onPrimaryContainer,
      );
      expect(find.textContaining('Color Lines by x4 Distance'), findsOneWidget);
      expect(
        find.textContaining('Color Slice Lines by x4 Distance'),
        findsOneWidget,
      );
      expect(Scene.color_by_x4.value, isFalse);
      expect(Slice.slice_color_by_x4.value, isFalse);
    });
  });

  group('SettingsScreen mobile layout tests', () {
    testWidgets('Checkboxes stay on the same row as their labels on mobile',
        (WidgetTester tester) async {
      const mobileSize = Size(360, 640);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = Settings.instance;
      PolyAppWidgetState.initSettings(settings);
      settings.status = SettingsStatus.Initialized;

      await tester.pumpWidget(
        MaterialApp(
          theme: settings.theme.theme_data,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Scroll through the SettingsScreen list and verify every Checkbox is
      // inside a Row with its label Text on the same horizontal row.
      final listView = find.byType(ListView);
      final checkedLabels = <String>{};

      for (int scrollStep = 0; scrollStep < 5; scrollStep++) {
        final checkboxFinders = find.byType(Checkbox);
        for (final element in checkboxFinders.evaluate()) {
          final checkboxFinder = find.byWidget(element.widget);
          final rowFinder = find.ancestor(
            of: checkboxFinder,
            matching: find.byType(Row),
          );
          expect(
            rowFinder,
            findsWidgets,
            reason: 'Checkbox must be grouped with its label in a Row',
          );
          final labelFinder = find.descendant(
            of: rowFinder.first,
            matching: find.byType(Text),
          );
          expect(labelFinder, findsOneWidget);

          final labelText = tester.widget<Text>(labelFinder).data ?? '';
          checkedLabels.add(labelText);

          final labelRect = tester.getRect(labelFinder);
          final checkboxRect = tester.getRect(checkboxFinder);
          expect(
            checkboxRect.left,
            greaterThanOrEqualTo(labelRect.right - 1.0),
            reason:
                'Checkbox for "$labelText" should be to the right of its label',
          );
          expect(
            (checkboxRect.center.dy - labelRect.center.dy).abs(),
            lessThanOrEqualTo(12.0),
            reason:
                'Checkbox for "$labelText" wrapped onto a different row than its label',
          );
        }
        await tester.drag(listView, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      expect(
        checkedLabels.length,
        greaterThanOrEqualTo(5),
        reason: 'Expected to inspect all boolean settings checkboxes',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsScreen has no overflow on mobile at 1.5x text scale',
        (WidgetTester tester) async {
      const mobileSize = Size(360, 640);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = Settings.instance;
      PolyAppWidgetState.initSettings(settings);
      settings.status = SettingsStatus.Initialized;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: mobileSize,
            textScaler: TextScaler.linear(1.5),
          ),
          child: MaterialApp(
            theme: settings.theme.theme_data,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      for (int i = 0; i < 6; i++) {
        expect(tester.takeException(), isNull);
        await tester.drag(listView, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  });
}
