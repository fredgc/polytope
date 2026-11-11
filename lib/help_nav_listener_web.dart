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

import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'help_nav_listener.dart';

HelpNavListener createHelpNavListener(HelpNavigateCallback onNavigate) =>
    _WebHelpNavListener(onNavigate);

class _WebHelpNavListener implements HelpNavListener {
  final HelpNavigateCallback onNavigate;
  late final JSFunction _listener;

  _WebHelpNavListener(this.onNavigate) {
    _listener = ((web.MessageEvent event) {
      final data = event.data;
      if (data != null && data.isA<JSString>()) {
        final str = (data as JSString).toDart;
        if (str.startsWith('help_navigate:')) {
          onNavigate(str.substring('help_navigate:'.length));
        }
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
  }
}
