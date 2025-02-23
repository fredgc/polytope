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
import 'widget.dart';
import 'settings.dart';

void main() async {
  print("RED: Start of main.");
  // The following is used by InAppWebView.
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }
  print("Building app.");
  MyAppBuilder builder = MyAppBuilder();
  PolyAppWidgetState.initSettings(Settings.instance);
  print("run app.");
  runApp(builder.makeApp());
  print("RED: Done with main.");
}

class MyAppBuilder {
  final settings = Settings();
  Map<String, WidgetBuilder> routes = {};

  MyAppBuilder() {
    routes[SettingsScreen.routeName] =
        (BuildContext context) => SettingsScreen();
    routes[HelpScreen.routeName] = (BuildContext context) => HelpScreen();
    routes[PolyAppWidget.routeName] = (BuildContext context) => PolyAppWidget();
  }

  MaterialApp makeApp() {
    return MaterialApp(
      title: "Polytope Demo",
      routes: routes,
      initialRoute: PolyAppWidget.routeName,
      debugShowCheckedModeBanner: false,
    );
  }
}
