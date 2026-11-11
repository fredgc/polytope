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

@Tags(['release_audit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polytope/l10n/l10n_extension.dart';
import 'package:polytope/main.dart';
import 'package:polytope/settings.dart';
import 'package:polytope/widget.dart';
import 'package:polytope/xr_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PolyAppWidgetState.initSettings(Settings.instance);
  });

  group('Release Accessibility & Layout Audit', () {
    const supportedLocales = LocaleController.supportedLocales;
    const viewports = <String, Size>{
      'mobile_compact': Size(360, 640),
      'tablet': Size(768, 1024),
      'desktop': Size(1280, 800),
    };

    for (final entry in viewports.entries) {
      final viewportName = entry.key;
      final viewportSize = entry.value;

      testWidgets(
        'Layout stability across locales on $viewportName with 1.5x text scaling',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final builder = MyAppBuilder(getXRSupport());

          for (final locale in supportedLocales) {
            LocaleController.currentLocale.value = locale;

            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: viewportSize,
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: builder.makeApp(),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason:
                  'Layout overflow/error under locale $locale on $viewportName',
            );
          }
        },
      );
    }

    testWidgets('Interactive elements satisfy accessibility guidelines',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final SemanticsHandle handle = tester.ensureSemantics();

      final builder = MyAppBuilder(getXRSupport());
      await tester.pumpWidget(builder.makeApp());
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });
}
