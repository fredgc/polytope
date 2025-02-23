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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'settings.dart';

class HelpScreen extends StatefulWidget {
  static const routeName = "/help";
  HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  double progress = 0;

  @override
  void initState() {
    super.initState();
  }

  void loadFile(String filename) async {
    if (webViewController == null) {
      print("Not loading $filename because controller is null.");
      return;
    }
    print("load file $filename.");
    webViewController?.loadFile(assetFilePath: "assets/$filename");
    // print("getMetaThemeColor = ${webViewController?.getMetaThemeColor}");
    Color? color = await webViewController!.getMetaThemeColor();
    // print("getMetaThemeColor = ${color}");
    // print("Done loading?");
  }

  AppBar appBar(BuildContext context) {
    // print("Building help page appbar.");
    final settings_button = IconButton(
      onPressed: () {
        Navigator.pushNamed(context, SettingsScreen.routeName);
      },
      icon: Icon(Icons.settings),
      tooltip: "Settings",
    );

    return AppBar(
      title: Text("Help"),
      leading: settings_button,
      actions: <Widget>[
        ElevatedButton(
          child: const Text("About"),
          onPressed: () {
            loadFile("about.html");
          },
        ),
        ElevatedButton(
          child: const Text("Overview"),
          onPressed: () {
            loadFile("help.html");
          },
        ),
        ElevatedButton(
          child: const Text("Slices"),
          onPressed: () {
            loadFile("slice.html");
          },
        ),
        ElevatedButton(
          child: const Text("Controls"),
          onPressed: () {
            loadFile("controls.html");
          },
        ),
        ElevatedButton(
          child: const Icon(Icons.close),
          onPressed: () {
            // print("close.");
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  InAppWebView webview(BuildContext c) {
    // print("Making web view.");
    var blank_page = InAppWebViewInitialData(data: """
      <!DOCTYPE html>
      <head></head> <body>Loading... </body></html>
      """);
    return InAppWebView(
      key: webViewKey,
      initialData: blank_page,
      // pullToRefreshController: pullToRefreshController,
      onWebViewCreated: (controller) {
        // print("onWebViewCreated");
        webViewController = controller;
        loadFile("about.html");
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        var uri = navigationAction.request.url!;
        // print("ORANGE: shouldOverrideUrlLoadin $uri.");
        // Any http, i.e. anything but a file.
        if (uri.toString().startsWith("http")) {
          InAppBrowser.openWithSystemBrowser(url: uri);
          return NavigationActionPolicy.ALLOW;
        }
        return NavigationActionPolicy.ALLOW;
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          this.progress = progress / 100;
        });
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (kDebugMode) {
          print(consoleMessage);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // print("Build help web view page.");
    return MaterialApp(
        theme: Settings.instance.theme.theme_data,
        home: Scaffold(
            appBar: appBar(context),
            body: SafeArea(
                child: Column(children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    Builder(builder: (BuildContext c) => webview(context)),
                    progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container(),
                  ],
                ),
              ),
            ]))));
  }
}
