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
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'color.dart';
import 'l10n/l10n_extension.dart';
import 'printer.dart';
import 'web_cache.dart';

enum SettingsStatus {
  NotInitialized, // Before Settings intiialized.
  Initialized,
}

abstract class Savable<T> {
  final String name; // Must be unique to be a key.
  final String description;
  final String tip;
  T value;

  bool visible = true; // If true, include this on the settings page.

  Savable(this.name, this.description, this.value, {this.tip = ""});

  void load(SharedPreferencesWithCache prefs);
  void save(SharedPreferencesWithCache prefs);

  // This is called when the theme changes.
  void updateTheme(ColorScheme scheme) {}

  // For building a UI.
  List<Widget?> build(BuildContext context, VoidCallback rebuild);
  void dispose() {}

  String localizedName(BuildContext context) {
    switch (name) {
      case "poly_color":
        return context.l10n.settingPolyColor;
      case "color_by_x4":
        return context.l10n.settingColorByX4;
      case "poly_edge_thickness":
        return context.l10n.settingPolyEdgeThickness;
      case "vertex_radius":
        return context.l10n.settingVertexRadius;
      case "enable_line_clipping":
        return context.l10n.settingEnableLineClipping;
      case "clip_gap_size":
        return context.l10n.settingClipGapSize;
      case "show_hotkey_buttons":
        return context.l10n.settingShowHotkeyButtons;
      case "show_pan_zoom_buttons":
        return context.l10n.settingShowPanZoomButtons;
      case "slice_color":
        return context.l10n.settingSliceColor;
      case "slice_color_by_x4":
        return context.l10n.settingSliceColorByX4;
      case "slice_edge_thickness":
        return context.l10n.settingSliceEdgeThickness;
      case "sticky_delay":
        return context.l10n.settingStickyDelay;
      case "sticky_radius":
        return context.l10n.settingStickyRadius;
      case "debug_logs":
        return context.l10n.settingDebugLogs;
      case "theme_color":
        return context.l10n.settingThemeColor;
      case "backgroud_color":
        return context.l10n.settingBackgroundColor;
      default:
        return description;
    }
  }

  @override
  String toString() {
    return "Savable $name ($description) value=$value";
  }
}

class SavableBool extends Savable<bool> {
  final bool Function()? defaultValueProvider;
  SavableBool(super.name, super.description, super.value,
      {super.tip = "", this.defaultValueProvider});
  @override
  void load(SharedPreferencesWithCache prefs) {
    final fallback = defaultValueProvider?.call() ?? value;
    value = prefs.getBool(name) ?? fallback;
    // print("Loaded $name -> $value");
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    // print("Saving $name -> $value");
    prefs.setBool(name, value);
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    if (Settings.instance.is_android_tv) {
      return [
        _TvBoolSettingRow(
          label: localizedName(context),
          value: value,
          onToggle: () {
            value = !value;
            rebuild();
          },
        ),
      ];
    }
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(child: Text("${localizedName(context)}: ")),
          Checkbox(
            value: value,
            onChanged: (bool? value) {
              this.value = value!;
              rebuild();
            },
          ),
        ],
      ),
    ];
  }
}

class _TvBoolSettingRow extends StatefulWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;

  const _TvBoolSettingRow({
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  State<_TvBoolSettingRow> createState() => _TvBoolSettingRowState();
}

class _TvBoolSettingRowState extends State<_TvBoolSettingRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onFocusChange: (focused) => setState(() => _focused = focused),
        onTap: widget.onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _focused
                ? scheme.primaryContainer.withValues(alpha: 0.25)
                : null,
            border: Border.all(
              color: _focused ? scheme.primary : Colors.transparent,
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(widget.label)),
              ExcludeFocus(
                child: Checkbox(
                  value: widget.value,
                  onChanged: (_) => widget.onToggle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavableDouble extends Savable<double> {
  TextEditingController? _controller;
  final double? min;
  final double? max;
  final int? divisions;

  SavableDouble(
    super.name,
    super.description,
    super.value, {
    super.tip = "",
    this.min,
    this.max,
    this.divisions,
  });

  @override
  void load(SharedPreferencesWithCache prefs) {
    value = prefs.getDouble(name) ?? value;
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    try {
      if (_controller != null) {
        value = double.parse(_controller!.text);
      }
    } catch (ex) {
      print("Parse error in ${_controller!.text} for $name");
    }
    prefs.setDouble(name, value);
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    if (min != null && max != null) {
      if (Settings.instance.is_android_tv) {
        return [
          _TvFriendlySlider(
            label: "${localizedName(context)}: ${value.toStringAsFixed(1)}",
            value: value.clamp(min!, max!),
            min: min!,
            max: max!,
            divisions: divisions,
            onChanged: (double newValue) {
              value = newValue;
              rebuild();
            },
          ),
        ];
      }
      return [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                  "${localizedName(context)}: ${value.toStringAsFixed(1)}"),
            ),
            _TvFriendlySlider(
              value: value.clamp(min!, max!),
              min: min!,
              max: max!,
              divisions: divisions,
              onChanged: (double newValue) {
                value = newValue;
                rebuild();
              },
            ),
          ],
        ),
      ];
    }

    _controller = TextEditingController();
    _controller!.text = value.toString();
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(child: Text("${localizedName(context)}: ")),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: tip),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}

/// Slider that supports Android TV D-pad navigation:
/// - On Android TV, uses select-to-edit: when focused (not editing), all four
///   arrow keys traverse focus; pressing Select/Enter enters edit mode where
///   Left/Right adjust the value, and Select/Enter/Back exits edit mode.
/// - On non-TV, Left/Right adjust directly while Up/Down traverse focus.
class _TvFriendlySlider extends StatefulWidget {
  final String? label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _TvFriendlySlider({
    this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  State<_TvFriendlySlider> createState() => _TvFriendlySliderState();
}

class _TvFriendlySliderState extends State<_TvFriendlySlider> {
  late final FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      debugLabel: 'SettingsSlider',
      onKeyEvent: _handleKeyEvent,
    );
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      setState(() {
        _isEditing = false;
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final isTv = Settings.instance.is_android_tv;

    if (key == LogicalKeyboardKey.arrowUp) {
      if (_isEditing) {
        setState(() => _isEditing = false);
      }
      node.focusInDirection(TraversalDirection.up);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_isEditing) {
        setState(() => _isEditing = false);
      }
      node.focusInDirection(TraversalDirection.down);
      return KeyEventResult.handled;
    }

    if (isTv) {
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space) {
        if (event is KeyDownEvent) {
          setState(() => _isEditing = !_isEditing);
        }
        return KeyEventResult.handled;
      }
      if (_isEditing &&
          (key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.goBack)) {
        setState(() => _isEditing = false);
        return KeyEventResult.handled;
      }
      if (_isEditing) {
        final step = widget.divisions != null && widget.divisions! > 0
            ? (widget.max - widget.min) / widget.divisions!
            : (widget.max - widget.min) * 0.05;
        if (key == LogicalKeyboardKey.arrowLeft) {
          widget.onChanged((widget.value - step).clamp(widget.min, widget.max));
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          widget.onChanged((widget.value + step).clamp(widget.min, widget.max));
          return KeyEventResult.handled;
        }
      } else {
        if (key == LogicalKeyboardKey.arrowLeft) {
          node.focusInDirection(TraversalDirection.left);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          node.focusInDirection(TraversalDirection.right);
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFocus = _focusNode.hasFocus;
    final slider = Slider(
      focusNode: _focusNode,
      value: widget.value,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      onChanged: widget.onChanged,
    );
    if (widget.label != null) {
      return SizedBox(
        width: double.infinity,
        child: Focus(
          focusNode: _focusNode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: _isEditing
                ? BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    border: Border.all(color: scheme.primary, width: 3.0),
                    borderRadius: BorderRadius.circular(8.0),
                  )
                : hasFocus
                    ? BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.2),
                        border: Border.all(color: scheme.primary, width: 2.5),
                        borderRadius: BorderRadius.circular(8.0),
                      )
                    : BoxDecoration(
                        border:
                            Border.all(color: Colors.transparent, width: 2.5),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(widget.label!)),
                SizedBox(
                  width: 280,
                  child: ExcludeFocus(
                    child: Slider(
                      value: widget.value,
                      min: widget.min,
                      max: widget.max,
                      divisions: widget.divisions,
                      onChanged: widget.onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: _isEditing
          ? BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.35),
              border: Border.all(color: scheme.primary, width: 3.0),
              borderRadius: BorderRadius.circular(8.0),
            )
          : hasFocus
              ? BoxDecoration(
                  border: Border.all(color: scheme.primary, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                )
              : null,
      child: slider,
    );
  }
}

// Add an EndOfRow to the settings to
class EndOfRow extends Savable<int> {
  static int count = 0;
  EndOfRow() : super("row $count", "UI Feature", count++);

  @override
  void load(SharedPreferencesWithCache prefs) {}
  @override
  void save(SharedPreferencesWithCache prefs) {}

  // For building a UI.
  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [null];
  }
}

class Settings {
  static final Settings _singleton = Settings();
  static Settings get instance => _singleton;

  SettingsStatus _status = SettingsStatus.NotInitialized;
  final StreamController<SettingsStatus> _statusStream =
      StreamController<SettingsStatus>.broadcast();

  String app_name = "uninitialized";
  String version = "uninitialized";
  String build_number = "-";
  bool no_keyboard = false;
  bool is_android_tv =
      const bool.fromEnvironment('ANDROID_TV', defaultValue: false);
  @visibleForTesting
  static bool? isAndroidTvOverride;
  @visibleForTesting
  static Map<String, Object>? testInitialValues;
  static const MethodChannel _platformChannel =
      MethodChannel('org.gchouse.polytope/platform');
  Future<void>? _loading_future;

  List<Savable> savables = []; //All settings.
  Map<String, Savable> savables_map = {};

  SavableTheme theme = SavableTheme();
  Color get background_color => theme.background_color.value;

  Settings();

  Future<void> initialize(BuildContext context) {
    // print("GREEN: initialize settings.");
    _checkKeyboard();
    theme.initialize(resetColorsAndNotify, context);
    resetColors();
    return load();
  }

  void _checkKeyboard() {
    if (foundation.kIsWeb) {
      print('Running on the web!');
    } else {
      print('Not running on the web!');
    }
    // Maybe assume there is no keyboard if
    no_keyboard = (foundation.defaultTargetPlatform == TargetPlatform.iOS ||
        foundation.defaultTargetPlatform == TargetPlatform.android);
    // print("noKeboard = $no_keyboard");
  }

  Future<void> _checkAndroidTv() async {
    if (isAndroidTvOverride != null) {
      is_android_tv = isAndroidTvOverride!;
      return;
    }
    if (is_android_tv) return;
    if (!foundation.kIsWeb &&
        foundation.defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _platformChannel.invokeMethod<bool>('isAndroidTv');
        is_android_tv = result ?? false;
      } catch (_) {
        is_android_tv = false;
      }
    }
  }

  SettingsStatus get status {
    return _status;
  }

  set status(SettingsStatus newStatus) {
    _status = newStatus;
    if (_statusStream.hasListener) _statusStream.add(_status);
  }

  // These stream is notified whenever the settings have been initialized or updated.
  Stream<SettingsStatus> statusStream() {
    return _statusStream.stream;
  }

  // This must be called before adding any other color settings if you want
  // them to be able to adjust based on the current theme.
  void addTheme() {
    add(theme);
  }

  void add(Savable savable) {
    if (savables_map.containsKey(savable.name)) {
      throw (StateError(
          "Setting name collision: $savable with ${savables_map[savable.name]}"));
    }
    savables.add(savable);
  }

  Future<void> load() {
    _loading_future ??= _load_future();
    return _loading_future!;
  }

  Future<SharedPreferencesWithCache> getPrefs() {
    // XXX This does not work because SavableTheme don't use name.
    // XXX Set<String> name_list = savables_map.keys.toSet();
    // XXX var options = SharedPreferencesWithCacheOptions(allowList: name_list);
    var options = SharedPreferencesWithCacheOptions();
    return SharedPreferencesWithCache.create(cacheOptions: options);
  }

  Future<void> _load_future() async {
    // print("In _load_future.");
    if (testInitialValues != null) {
      await _checkAndroidTv();
      for (var s in savables) {
        if (s is SavableBool) {
          final override = testInitialValues![s.name];
          if (override is bool) {
            s.value = override;
          } else if (s.defaultValueProvider != null) {
            s.value = s.defaultValueProvider!();
          }
        }
      }
      status = SettingsStatus.Initialized;
      _loading_future = null;
      return;
    }
    await dsleep("settings", 3);
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      app_name = packageInfo.appName;
      version = packageInfo.version;
      build_number = packageInfo.buildNumber;
      print("Package info: $app_name, $build_number, $version");
    } catch (_) {
      // PackageInfo may be unavailable in unit tests.
    }
    await _checkAndroidTv();
    try {
      var prefs = await getPrefs();
      // print("prefs = $prefs");
      // theme.load(prefs);
      for (var s in savables) {
        s.load(prefs);
      }
    } catch (_) {
      for (var s in savables) {
        if (s is SavableBool && s.defaultValueProvider != null) {
          s.value = s.defaultValueProvider!();
        }
      }
    }
    // print("Settings done initialized.");
    status = SettingsStatus.Initialized;
    _loading_future = null;
    // print("Finished loading settings.");
    if (foundation.kIsWeb) {
      final clientVersion =
          build_number.isNotEmpty ? '$version+$build_number' : version;
      unawaited(checkServerVersionAndReload(clientVersion));
    }
  }

  Future<void> save() async {
    // print("saving settings.");
    final prefs = await getPrefs();
    for (var s in savables) {
      s.save(prefs);
    }
  }

  void notify() {
    // Notify all the other widgets, so that they redraw with latest settings.
    if (_statusStream.hasListener) _statusStream.add(_status);
  }

  // This is called when the theme has been updated.
  void resetColorsAndNotify() {
    // print("reset colors and notify");
    resetColors();
    notify();
  }

  // Set colors based on light/dark theme mode. Previously chosen colors will
  // be erased.
  void resetColors() {
    // print("--- reset colors using brightnss = ${theme.scheme.brightness}");
    for (var s in savables) {
      s.updateTheme(theme.scheme);
    }
  }
}

class SettingsScreen extends StatefulWidget {
  static const routeName = "/settings";
  const SettingsScreen({super.key});
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late StreamSubscription _statusListener;

  @override
  void initState() {
    // print("Settings.initState.");
    super.initState();
    _statusListener = Settings.instance.statusStream().listen((status) {
      // print("Settings listener: heard status = $status");
      setState(() {
        // print("Settings own listener heard status changed. set state.");
      });
    });
  }

  @override
  void dispose() {
    // print("dispose of settings widget.");
    _statusListener.cancel();
    for (var s in Settings.instance.savables) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Settings.instance.status == SettingsStatus.NotInitialized) {
      Settings.instance.initialize(context).then((_) {
        setState(() {});
      });
      return Text(context.l10n.initializingSettings);
    }
    // print("Building SettingsScreen.");
    List<Widget?> children = _pickChildren(context);
    List<List<Widget>> rows = [
      for (var s in MyIterator(children))
        if (s.isNotEmpty) s
    ];
    final isTv = Settings.instance.is_android_tv;
    final list = ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: rows.length,
      itemBuilder: (buildContext, int index) {
        if (isTv && rows[index].length == 1) {
          return rows[index].first;
        }
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: rows[index],
        );
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
    final scaffold = Scaffold(
      appBar: appBar(context),
      body: SafeArea(child: list),
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

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: Text(context.l10n.settingsTitle),
      actions: <Widget>[
        const LanguageMenuButton(),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.l10n.closeTooltip,
          onPressed: () {
            quit(context);
          },
        ),
        IconButton(
          icon: const Icon(Icons.done),
          tooltip: context.l10n.doneTooltip,
          onPressed: () {
            done(context);
          },
        ),
      ],
    );
  }

  // Get the list of widgets from all the savable objects.
  // Then flatten this list of lists so we get one big list.
  List<Widget?> _pickChildren(BuildContext context) {
    if (Settings.instance.status == SettingsStatus.NotInitialized) {
      return [Text(context.l10n.initializingApp)];
    }
    List<List<Widget?>> list1 = [
      [
        SelectableText(context.l10n.settingAppVersion(
            Settings.instance.app_name,
            Settings.instance.version,
            Settings.instance.build_number)),
        null,
      ],
      for (var s in Settings.instance.savables)
        if (s.visible && !(Settings.instance.is_android_tv && s is EndOfRow))
          [
            ...s.build(context, () {
              setState(() {});
            }),
            if (Settings.instance.is_android_tv) null,
          ],
      [
        null,
        ElevatedButton(
          onPressed: () => done(context),
          child: Text(context.l10n.doneButton),
        ),
        ElevatedButton(
          onPressed: () => quit(context),
          child: Text(context.l10n.cancelButton),
        ),
      ]
    ];
    // Flatten the list.
    return [
      for (var sublist in list1)
        for (var w in sublist) w,
    ];
  }

  void done(BuildContext context) async {
    // print("GREEN: Done with settings.");
    await Settings.instance.save();
    Settings.instance.notify();
    Navigator.pop(context);
  }

  void quit(BuildContext context) async {
    // print("RED: Done with settings. Don't save.");
    await Settings.instance.load();
    Settings.instance.notify();
    Navigator.pop(context);
  }
}

// Unflatten a list of widgets into a list of lists, breaking at nulls.
// [a, b, null, c, d, e, null, f] => [[a,b], [c,d,e], [f]]
class MyIterator extends Iterable<List<Widget>>
    implements Iterator<List<Widget>> {
  List<Widget?> input;
  List<Widget> _current = [];
  @override
  List<Widget> get current => _current;
  @override
  Iterator<List<Widget>> get iterator => this;

  MyIterator(this.input);

  @override
  bool moveNext() {
    if (input.isEmpty) return false;
    int i = input.indexWhere((s) => s == null);
    if (i < 0) {
      _current = input.nonNulls.toList();
      input = [];
      return true;
    }
    _current = input.sublist(0, i).nonNulls.toList();
    input = input.sublist(i + 1);
    return true;
  }
}
