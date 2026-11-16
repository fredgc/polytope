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
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'help_nav_listener.dart';
import 'l10n/l10n_extension.dart';
import 'settings.dart';
import 'webview_stub.dart' if (dart.library.js_interop) 'webview_web.dart';

class HelpScreen extends StatefulWidget {
  static const routeName = "/help";
  const HelpScreen({super.key});

  static bool isExternalUrl(String href) {
    final trimmed = href.trim();
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('mailto:');
  }

  static String cleanNavTarget(String href) {
    String target = href.trim();
    if (target.contains('#')) {
      target = target.split('#').first;
    }
    if (target.contains('?')) {
      target = target.split('?').first;
    }
    if (target.startsWith('./')) {
      target = target.substring(2);
    }
    return target;
  }

  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String generateThemeCss(ColorScheme scheme) {
    final bgHex = colorToHex(scheme.surface);
    final textHex = colorToHex(scheme.onSurface);
    final sectionHex = colorToHex(scheme.surfaceContainerHighest);
    final primaryHex = colorToHex(scheme.primary);
    final borderHex = colorToHex(scheme.outline);

    return '''
<style id="theme-style">
html, body, .container {
  background: $bgHex !important;
  color: $textHex !important;
}
section {
  background: $sectionHex !important;
  border: 1px solid $borderHex !important;
  color: $textHex !important;
}
h1, h2, h3, h4, .title {
  color: $primaryHex !important;
}
p, li, td, th {
  color: $textHex !important;
}
table, th, td {
  border-color: $borderHex !important;
}
th {
  background: $sectionHex !important;
  color: $primaryHex !important;
}
a {
  color: $primaryHex !important;
}
a:visited {
  color: $primaryHex !important;
}
a:hover {
  color: $textHex !important;
}
code {
  background: $sectionHex !important;
  color: $textHex !important;
  padding: 2px 4px !important;
  border-radius: 4px !important;
}
nav {
  background-color: $sectionHex !important;
}
header, footer {
  background: inherit !important;
  color: $textHex !important;
}
</style>
''';
  }

  static String generateDarkCss(ColorScheme scheme) => generateThemeCss(scheme);

  static String generateLightCss([ColorScheme? scheme]) => generateThemeCss(
        scheme ??
            ColorScheme.fromSeed(
              seedColor: Colors.purple,
              brightness: Brightness.light,
            ),
      );

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late final WebViewController webViewController;
  double progress = 0;
  String currentFile = "about.html";
  String? _lastLocale;
  Brightness? _lastBrightness;
  HelpNavListener? _helpNavListener;
  StreamSubscription<SettingsStatus>? _statusListener;

  static const _navScript = '''
<script>
document.addEventListener('click', function(e) {
  var a = e.target.closest('a');
  if (a) {
    var href = a.getAttribute('href');
    if (href && !href.startsWith('#')) {
      e.preventDefault();
      if (window.parent && window.parent !== window) {
        window.parent.postMessage('help_navigate:' + href, '*');
      }
      if (window.HelpNavigate && window.HelpNavigate.postMessage) {
        window.HelpNavigate.postMessage(href);
      }
    }
  }
});
</script>
''';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      initWebviewPlatform();
    }
    webViewController = WebViewController();
    try {
      webViewController.setBackgroundColor(
        Settings.instance.theme.scheme.surface,
      );
    } catch (_) {}
    if (!kIsWeb) {
      try {
        webViewController
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'HelpNavigate',
            onMessageReceived: (JavaScriptMessage message) {
              _handleNavigation(message.message);
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int p) {
                if (mounted) {
                  setState(() {
                    progress = p / 100.0;
                  });
                }
              },
              onPageFinished: (String url) {
                if (mounted && progress < 1.0) {
                  setState(() {
                    progress = 1.0;
                  });
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                final urlString = request.url;
                if (HelpScreen.isExternalUrl(urlString)) {
                  final uri = Uri.tryParse(urlString.trim());
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  return NavigationDecision.prevent;
                }
                if (urlString != 'about:blank' &&
                    !urlString.startsWith('data:')) {
                  _handleNavigation(urlString);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          );
      } catch (_) {}
    } else {
      progress = 1.0;
    }
    LocaleController.currentLocale.addListener(_onLocaleChanged);
    _statusListener = Settings.instance.statusStream().listen((status) {
      if (mounted) {
        loadFile(currentFile);
        setState(() {});
      }
    });
    _helpNavListener = HelpNavListener(_handleNavigation);
    loadFile(currentFile);
  }

  @override
  void dispose() {
    LocaleController.currentLocale.removeListener(_onLocaleChanged);
    _statusListener?.cancel();
    _helpNavListener?.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) {
      loadFile(currentFile);
      setState(() {});
    }
  }

  void _handleNavigation(String href) async {
    if (HelpScreen.isExternalUrl(href)) {
      final uri = Uri.tryParse(href.trim());
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final target = HelpScreen.cleanNavTarget(href);
    if (target.isNotEmpty) {
      loadFile(target);
    }
  }

  String _effectiveLanguage() {
    final active = LocaleController.currentLocale.value?.languageCode;
    if (active != null && active.isNotEmpty) {
      return active;
    }
    final systemLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (LocaleController.supportedLocales
        .any((l) => l.languageCode == systemLang)) {
      return systemLang;
    }
    return 'en';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    final brightness = Theme.of(context).brightness;
    if ((_lastLocale != null && _lastLocale != locale) ||
        (_lastBrightness != null && _lastBrightness != brightness)) {
      loadFile(currentFile);
    }
    _lastLocale = locale;
    _lastBrightness = brightness;
  }

  void loadFile(String filename) async {
    final baseWithExt =
        filename.endsWith('.html') ? filename : '$filename.html';
    final cleanBase =
        baseWithExt.replaceAll(RegExp(r'_[a-z]{2}\.html$'), '.html');
    currentFile = cleanBase;
    final lang = _effectiveLanguage();
    String target = cleanBase;
    if (lang != 'en') {
      final dot = cleanBase.lastIndexOf('.');
      if (dot != -1) {
        target =
            "${cleanBase.substring(0, dot)}_$lang${cleanBase.substring(dot)}";
      }
    }
    print("load file $target.");
    String htmlContent;
    try {
      htmlContent = await rootBundle.loadString('assets/$target');
    } catch (_) {
      try {
        htmlContent = await rootBundle.loadString('assets/$cleanBase');
      } catch (ex) {
        print("RED: error loading $cleanBase. $ex");
        return;
      }
    }
    try {
      final css = await rootBundle.loadString('assets/css/doc_style.css');
      htmlContent =
          htmlContent.replaceFirst('</head>', '<style>$css</style></head>');
    } catch (_) {}

    final scheme = Settings.instance.theme.scheme;
    final themeCss = HelpScreen.generateThemeCss(scheme);
    if (htmlContent.contains('</head>')) {
      htmlContent = htmlContent.replaceFirst('</head>', '$themeCss</head>');
    } else {
      htmlContent = '$themeCss$htmlContent';
    }

    if (htmlContent.contains('</body>')) {
      htmlContent = htmlContent.replaceFirst('</body>', '$_navScript</body>');
    } else {
      htmlContent = '$htmlContent$_navScript';
    }

    try {
      await webViewController.loadHtmlString(htmlContent);
    } catch (e) {
      print("Error loading data into webview: $e");
    }
  }

  AppBar appBar(BuildContext context) {
    final settingsButton = IconButton(
      onPressed: () {
        Navigator.pushNamed(context, SettingsScreen.routeName);
      },
      icon: const Icon(Icons.settings),
      tooltip: context.l10n.settingsTooltip,
    );

    return AppBar(
      title: Text(context.l10n.helpTitle),
      leading: settingsButton,
      actions: <Widget>[
        ElevatedButton(
          child: Text(context.l10n.aboutTab),
          onPressed: () {
            loadFile("about.html");
          },
        ),
        ElevatedButton(
          child: Text(context.l10n.privacyTab),
          onPressed: () {
            loadFile("privacy.html");
          },
        ),
        ElevatedButton(
          child: Text(context.l10n.termsTab),
          onPressed: () {
            loadFile("terms.html");
          },
        ),
        ElevatedButton(
          child: Text(context.l10n.overviewTab),
          onPressed: () {
            loadFile("help.html");
          },
        ),
        ElevatedButton(
          child: Text(context.l10n.slicesTab),
          onPressed: () {
            loadFile("slice.html");
          },
        ),
        ElevatedButton(
          child: Text(context.l10n.controlsTab),
          onPressed: () {
            loadFile("controls.html");
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.l10n.closeTooltip,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget webview(BuildContext c) {
    return WebViewWidget(controller: webViewController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: SafeArea(
        child: Column(
          children: <Widget>[
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
          ],
        ),
      ),
    );
  }
}
