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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polytope/l10n/l10n_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Localization tests', () {
    testWidgets('Renders strings in English', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                appBar: AppBar(title: Text(context.l10n.appTitle)),
                body: Column(
                  children: [
                    Text(context.l10n.polytopeCube),
                    Text(context.l10n.movementRotate3),
                    Text(context.l10n.settingsTitle),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Polytope Demo'), findsOneWidget);
      expect(find.text('Cube'), findsOneWidget);
      expect(find.text('Rotate R3'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Renders strings in Spanish', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                appBar: AppBar(title: Text(context.l10n.appTitle)),
                body: Column(
                  children: [
                    Text(context.l10n.polytopeCube),
                    Text(context.l10n.movementRotate3),
                    Text(context.l10n.settingsTitle),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Demostración de politopos'), findsOneWidget);
      expect(find.text('Cubo'), findsOneWidget);
      expect(find.text('Rotar R3'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
    });

    test('LocaleController sets and clears locale and language codes',
        () async {
      await LocaleController.setLocale(const Locale('es'));
      expect(LocaleController.currentLocale.value, const Locale('es'));
      expect(LocaleController.currentLanguageCode, 'es');

      await LocaleController.setLocale(const Locale('en'));
      expect(LocaleController.currentLocale.value, const Locale('en'));
      expect(LocaleController.currentLanguageCode, 'en');

      await LocaleController.setLocale(null);
      expect(LocaleController.currentLocale.value, isNull);
      expect(LocaleController.currentLanguageCode, 'auto');

      await LocaleController.setLanguageCode('es');
      expect(LocaleController.currentLocale.value, const Locale('es'));
      expect(LocaleController.currentLanguageCode, 'es');

      await LocaleController.setLanguageCode('auto');
      expect(LocaleController.currentLocale.value, isNull);
      expect(LocaleController.currentLanguageCode, 'auto');
    });

    testWidgets('LanguageMenuButton switches to Spanish and back to Auto',
        (WidgetTester tester) async {
      await LocaleController.setLocale(null);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.currentLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                appBar: AppBar(
                  title: Builder(
                    builder: (context) => Text(context.l10n.appTitle),
                  ),
                  actions: const [LanguageMenuButton()],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Polytope Demo'), findsOneWidget);

      // Open the language menu
      await tester.tap(find.byType(LanguageMenuButton));
      await tester.pumpAndSettle();

      // Tap Spanish
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(LocaleController.currentLocale.value, const Locale('es'));
      expect(find.text('Demostración de politopos'), findsOneWidget);

      // Open the language menu again
      await tester.tap(find.byType(LanguageMenuButton));
      await tester.pumpAndSettle();

      // Tap Auto
      await tester.tap(find.text('Automático'));
      await tester.pumpAndSettle();

      expect(LocaleController.currentLocale.value, isNull);
      expect(find.text('Polytope Demo'), findsOneWidget);
    });

    testWidgets('Switching locale dynamically updates UI including Auto (null)',
        (WidgetTester tester) async {
      await LocaleController.setLocale(null);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.currentLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (BuildContext context) {
                  return Scaffold(
                    appBar: AppBar(title: Text(context.l10n.appTitle)),
                  );
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Polytope Demo'), findsOneWidget);

      await LocaleController.setLocale(const Locale('es'));
      await tester.pumpAndSettle();
      expect(find.text('Demostración de politopos'), findsOneWidget);

      await LocaleController.setLocale(null);
      await tester.pumpAndSettle();
      expect(find.text('Polytope Demo'), findsOneWidget);
    });

    testWidgets('Switching from Spanish to Auto (null) switches to English',
        (WidgetTester tester) async {
      await LocaleController.setLocale(const Locale('es'));
      await tester.pumpWidget(
        ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.currentLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              locale: locale,
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                if (deviceLocale != null) {
                  for (final supported in supportedLocales) {
                    if (supported.languageCode == deviceLocale.languageCode) {
                      return supported;
                    }
                  }
                }
                return const Locale('en');
              },
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Text(context.l10n.polytopeCube),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cubo'), findsOneWidget);

      await LocaleController.setLocale(null);
      await tester.pumpAndSettle();

      expect(find.text('Cube'), findsOneWidget);
    });

    test('All supported locales have valid translations', () {
      for (final locale in LocaleController.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        expect(l10n.appTitle.isNotEmpty, isTrue);
        expect(l10n.switchLanguageTooltip.isNotEmpty, isTrue);
        expect(l10n.polytopeCube.isNotEmpty, isTrue);
      }
    });

    test('All localized ARB files maintain key parity with app_en.arb', () {
      final enContent = File('lib/l10n/app_en.arb').readAsStringSync();
      final enJson = jsonDecode(enContent) as Map<String, dynamic>;
      final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();

      final targetArbFiles = [
        'app_de.arb',
        'app_es.arb',
        'app_fr.arb',
        'app_ja.arb',
        'app_lt.arb',
        'app_pt.arb',
        'app_zh.arb',
      ];

      for (final file in targetArbFiles) {
        final content = File('lib/l10n/$file').readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        for (final key in enKeys) {
          expect(
            json.containsKey(key),
            isTrue,
            reason: 'ARB file $file is missing key "$key"',
          );
        }
      }
    });
  });
}
