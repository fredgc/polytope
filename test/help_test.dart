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
import 'package:polytope/help.dart';
import 'package:polytope/help_nav_listener.dart';

void main() {
  test('Help navigation target parsing and external URL detection', () {
    expect(HelpScreen.isExternalUrl('https://example.com'), isTrue);
    expect(HelpScreen.isExternalUrl('http://example.com/page'), isTrue);
    expect(HelpScreen.isExternalUrl('mailto:user@example.com'), isTrue);
    expect(HelpScreen.isExternalUrl('slice.html'), isFalse);
    expect(HelpScreen.isExternalUrl('controls.html'), isFalse);
    expect(HelpScreen.isExternalUrl('./help_es.html'), isFalse);

    expect(HelpScreen.cleanNavTarget('slice.html'), 'slice.html');
    expect(HelpScreen.cleanNavTarget('./slice.html'), 'slice.html');
    expect(
      HelpScreen.cleanNavTarget('controls.html#section1'),
      'controls.html',
    );
    expect(HelpScreen.cleanNavTarget('help_es.html?ref=1'), 'help_es.html');
  });

  test('HelpNavListener initializes and disposes cleanly', () {
    String? navigated;
    final listener = HelpNavListener((href) {
      navigated = href;
    });
    expect(navigated, isNull);
    listener.dispose();
  });

  test('HelpScreen colorToHex converts colors correctly', () {
    expect(HelpScreen.colorToHex(const Color(0xFF000000)), '#000000');
    expect(HelpScreen.colorToHex(const Color(0xFFFFFFFF)), '#ffffff');
    expect(HelpScreen.colorToHex(const Color(0xFF1C1B1F)), '#1c1b1f');
  });

  test('HelpScreen generateDarkCss and generateLightCss produce valid styles',
      () {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.dark,
    );
    final darkCss = HelpScreen.generateDarkCss(darkScheme);
    expect(darkCss, contains('<style id="theme-style">'));
    expect(darkCss, contains('background:'));
    expect(darkCss, contains('color:'));
    expect(darkCss, contains(HelpScreen.colorToHex(darkScheme.surface)));

    final lightScheme = ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.light,
    );
    final lightCss = HelpScreen.generateLightCss(lightScheme);
    expect(lightCss, contains('<style id="theme-style">'));
    expect(lightCss, contains(HelpScreen.colorToHex(lightScheme.surface)));
    expect(
      lightCss,
      contains(HelpScreen.colorToHex(lightScheme.surfaceContainerHighest)),
    );
  });

  test('HelpScreen prepareHtmlContent inlines CSS, theme, and link handling',
      () {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.dark,
    );
    const sampleHtml = '''<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="css/doc_style.css" />
</head>
<body>
  <p>See <a href="help.html">Overview</a> and <a href="https://policies.google.com/privacy">Privacy</a>.</p>
</body>
</html>''';

    final prepared = HelpScreen.prepareHtmlContent(
      sampleHtml,
      cssContent: 'body { margin: 0; }',
      isDark: true,
      colorScheme: scheme,
    );

    expect(prepared, isNot(contains('href="css/doc_style.css"')));
    expect(prepared, contains('<style>body { margin: 0; }</style>'));
    expect(prepared, contains('<style id="theme-style">'));
    expect(prepared, contains('<html class="dark-theme">'));
    expect(
      prepared,
      contains(
        '<a href="https://policies.google.com/privacy" target="_blank" rel="noopener">',
      ),
    );
    expect(prepared, contains('<a href="help.html">Overview</a>'));
    expect(prepared, contains("window.parent.postMessage('help_navigate:'"));
    expect(prepared, contains('window.HelpNavigate.postMessage(href)'));
  });
}
