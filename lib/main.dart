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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'help.dart';
import 'l10n/l10n_extension.dart';
import 'widget.dart';
import 'settings.dart';
import 'xr_support.dart';

void main() async {
  print("RED: FDGC: Start of main.");

  XRSupport xr = getXRSupport();
  await xr.checkSupport();
  print("xr.supported  = ${xr.supported}.");

  // The following is used by InAppWebView.
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.initialize();
  print("BLUE: kIsWeb = $kIsWeb.");
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    print("BLUE: not web, and is Android.");
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }
  print("Building app.");
  MyAppBuilder builder = MyAppBuilder(xr);
  PolyAppWidgetState.initSettings(Settings.instance);
  print("run app.");
  runApp(builder.makeApp());
  print("RED: Done with main.");
}

class MyAppBuilder {
  final settings = Settings();
  Map<String, WidgetBuilder> routes = {};
  final XRSupport xr;

  MyAppBuilder(this.xr) {
    routes[SettingsScreen.routeName] =
        (BuildContext context) => const SettingsScreen();
    routes[HelpScreen.routeName] = (BuildContext context) => const HelpScreen();
    routes[PolyAppWidget.routeName] =
        (BuildContext context) => PolyAppWidget(xr);
  }

  Widget makeApp() {
    return StreamBuilder<SettingsStatus>(
      stream: Settings.instance.statusStream(),
      initialData: Settings.instance.status,
      builder: (context, _) {
        return ValueListenableBuilder<Locale?>(
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
              onGenerateTitle: (context) => context.l10n.appTitle,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: Settings.instance.theme.theme_data,
              routes: routes,
              initialRoute: PolyAppWidget.routeName,
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
