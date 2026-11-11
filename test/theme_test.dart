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
import 'package:polytope/color.dart';
import 'package:polytope/l10n/l10n_extension.dart';
import 'package:polytope/main.dart';
import 'package:polytope/settings.dart';
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

      final theme = Theme.of(tester.element(scaffoldFinder));
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, SavableTheme.darkPurpleBackground);
      expect(theme.scaffoldBackgroundColor, SavableTheme.darkPurpleBackground);
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final theme = Theme.of(tester.element(scaffoldFinder));
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, SavableTheme.darkPurpleBackground);
      expect(theme.scaffoldBackgroundColor, SavableTheme.darkPurpleBackground);
    });
  });
}
