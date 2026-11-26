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
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey, rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'help_nav_listener.dart';
import 'l10n/l10n_extension.dart';
import 'settings.dart';
import 'webview_stub.dart' if (dart.library.js_interop) 'webview_web.dart';

class HelpScreen extends StatefulWidget {
  static const routeName = "/help";
  const HelpScreen({super.key});

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

  /// Prepares raw HTML documentation for display in the WebView.
  static String prepareHtmlContent(
    String htmlContent, {
    required String cssContent,
    required bool isDark,
    ColorScheme? colorScheme,
  }) {
    // Ensure external links open in a new tab/window as a fallback if JS
    // interception does not handle them.
    final anchorTargetRegExp = RegExp(
      r'<a\s+href="(https?://[^"]+)"(?![^>]*\btarget=)',
    );
    htmlContent = htmlContent.replaceAllMapped(anchorTargetRegExp, (match) {
      return '<a href="${match.group(1)}" target="_blank" rel="noopener"';
    });

    // Replace stylesheet link with inlined CSS to avoid relative path loading
    // issues on web and mobile.
    final linkRegExp = RegExp(
      r'''<link\s+rel=["']stylesheet["']\s+href=["'][^"']*doc_style\.css["']\s*/?>''',
    );
    final themeCss = colorScheme != null ? generateThemeCss(colorScheme) : '';
    final combinedCss = '<style>$cssContent</style>$themeCss';
    if (htmlContent.contains(linkRegExp)) {
      htmlContent = htmlContent.replaceFirst(linkRegExp, combinedCss);
    } else if (htmlContent.contains('</head>')) {
      htmlContent = htmlContent.replaceFirst('</head>', '$combinedCss</head>');
    } else {
      htmlContent = '<head>$combinedCss</head>$htmlContent';
    }

    final themeClass = isDark ? 'dark-theme' : 'light-theme';
    if (htmlContent.contains('<html')) {
      htmlContent = htmlContent.replaceFirst(
        '<html',
        '<html class="$themeClass"',
      );
    } else if (htmlContent.contains('<body')) {
      htmlContent = htmlContent.replaceFirst(
        '<body',
        '<body class="$themeClass"',
      );
    }

    if (htmlContent.contains('</body>')) {
      htmlContent = htmlContent.replaceFirst('</body>', '$_navScript</body>');
    } else {
      htmlContent = '$htmlContent$_navScript';
    }

    return htmlContent;
  }

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late final WebViewController webViewController;
  double progress = 0;
  String currentFile = "about.html";
  bool _isMenuOpen = false;
  String? _lastLocale;
  Brightness? _lastBrightness;
  HelpNavListener? _helpNavListener;
  StreamSubscription<SettingsStatus>? _statusListener;

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
                    _launchExternalUrl(uri);
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
        try {
          webViewController.setBackgroundColor(
            Settings.instance.theme.scheme.surface,
          );
        } catch (_) {}
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

  Future<void> _launchExternalUrl(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // External browser may be unavailable (e.g. Android TV).
    }
  }

  void _handleNavigation(String href) async {
    if (HelpScreen.isExternalUrl(href)) {
      final uri = Uri.tryParse(href.trim());
      if (uri != null) {
        await _launchExternalUrl(uri);
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
    if (currentFile != cleanBase && mounted) {
      setState(() {
        currentFile = cleanBase;
      });
    } else {
      currentFile = cleanBase;
    }
    final lang = _effectiveLanguage();
    String target = cleanBase;
    if (lang != 'en') {
      final dot = cleanBase.lastIndexOf('.');
      if (dot != -1) {
        target =
            "${cleanBase.substring(0, dot)}_$lang${cleanBase.substring(dot)}";
      }
    }
    String htmlContent;
    try {
      htmlContent = await rootBundle.loadString('assets/$target');
    } catch (_) {
      try {
        htmlContent = await rootBundle.loadString('assets/$cleanBase');
      } catch (ex) {
        debugPrint("RED: error loading $cleanBase. $ex");
        return;
      }
    }
    String cssContent = '';
    try {
      cssContent = await rootBundle.loadString('assets/css/doc_style.css');
    } catch (_) {}

    final scheme = Settings.instance.theme.scheme;
    htmlContent = HelpScreen.prepareHtmlContent(
      htmlContent,
      cssContent: cssContent,
      isDark: scheme.brightness == Brightness.dark,
      colorScheme: scheme,
    );

    try {
      await webViewController.loadHtmlString(htmlContent);
    } catch (e) {
      debugPrint("Error loading data into webview: $e");
    }
  }

  AppBar appBar(BuildContext context, {required bool isWideScreen}) {
    final l10n = context.l10n;
    return AppBar(
      title: Text(
        (!isWideScreen && _isMenuOpen) ? l10n.helpMenu : l10n.helpTitle,
      ),
      leading: isWideScreen
          ? null
          : IconButton(
              icon: Icon(_isMenuOpen ? Icons.close : Icons.menu),
              tooltip: _isMenuOpen ? l10n.closeTooltip : l10n.openDrawerTooltip,
              onPressed: () {
                setState(() {
                  _isMenuOpen = !_isMenuOpen;
                });
              },
            ),
      automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, SettingsScreen.routeName);
          },
          icon: const Icon(Icons.settings),
          tooltip: l10n.settingsTooltip,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.closeTooltip,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget buildNavigationList(BuildContext context, {required bool isSidebar}) {
    final l10n = context.l10n;
    final items = <Widget>[
      if (isSidebar) ...[
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Text(
            l10n.appTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
      ] else ...[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                l10n.appTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.helpTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
        child: Text(
          l10n.userGuidesSection,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      buildDrawerItem(
        context,
        l10n.aboutTab,
        "about.html",
        Icons.info_outline,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        l10n.overviewTab,
        "help.html",
        Icons.visibility_outlined,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        l10n.slicesTab,
        "slice.html",
        Icons.layers_outlined,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        l10n.controlsTab,
        "controls.html",
        Icons.tune,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        l10n.privacyTab,
        "privacy.html",
        Icons.privacy_tip_outlined,
        isSidebar: isSidebar,
      ),
      buildDrawerItem(
        context,
        l10n.termsTab,
        "terms.html",
        Icons.gavel_outlined,
        isSidebar: isSidebar,
      ),
    ];
    return ListView(padding: EdgeInsets.zero, children: items);
  }

  Widget buildDrawerItem(
    BuildContext context,
    String title,
    String filename,
    IconData icon, {
    required bool isSidebar,
  }) {
    final isSelected = currentFile == filename;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        if (!isSidebar) {
          setState(() {
            _isMenuOpen = false;
          });
        }
        setState(() {
          currentFile = filename;
        });
        loadFile(filename);
      },
    );
  }

  Future<void> _scrollWebViewUpOrLeaveFocus(FocusNode node) async {
    try {
      final result = await webViewController
          .runJavaScriptReturningResult('window.scrollY');
      final scrollY = double.tryParse(result.toString()) ?? 0.0;
      if (scrollY <= 1.0) {
        node.focusInDirection(TraversalDirection.up);
        return;
      }
      await webViewController.runJavaScript('window.scrollBy(0, -140);');
    } catch (_) {
      node.focusInDirection(TraversalDirection.up);
    }
  }

  Widget webview(BuildContext c) {
    final view = WebViewWidget(controller: webViewController);
    if (kIsWeb) {
      return view;
    }
    return Focus(
      debugLabel: 'HelpWebView',
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowDown) {
            webViewController.runJavaScript('window.scrollBy(0, 140);');
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowUp) {
            unawaited(_scrollWebViewUpOrLeaveFocus(node));
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.pageDown) {
            webViewController.runJavaScript('window.scrollBy(0, 420);');
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.pageUp) {
            webViewController.runJavaScript('window.scrollBy(0, -420);');
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (BuildContext focusContext) {
          final hasFocus = Focus.of(focusContext).hasFocus;
          return Container(
            decoration: hasFocus
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(focusContext).colorScheme.primary,
                      width: 2.5,
                    ),
                  )
                : null,
            child: view,
          );
        },
      ),
    );
  }

  Widget _buildWebViewPane(BuildContext context) {
    return Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 750;
    final scaffold = Scaffold(
      appBar: appBar(context, isWideScreen: isWideScreen),
      body: SafeArea(
        child: isWideScreen
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 280,
                    child: Material(
                      color: Theme.of(context).cardColor,
                      child: buildNavigationList(context, isSidebar: true),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: _buildWebViewPane(context)),
                ],
              )
            : (_isMenuOpen
                ? Material(
                    color: Theme.of(context).cardColor,
                    child: buildNavigationList(context, isSidebar: false),
                  )
                : _buildWebViewPane(context)),
      ),
    );
    if (Settings.instance.is_android_tv) {
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 27),
          child: scaffold,
        ),
      );
    }
    return scaffold;
  }
}
