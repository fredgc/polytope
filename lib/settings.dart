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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'color.dart';
import 'printer.dart';

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

  String toString() {
    return "Savable $name ($description) value=$value";
  }
}

class SavableBool extends Savable<bool> {
  SavableBool(super.name, super.description, super.value, {super.tip = ""});
  void load(SharedPreferencesWithCache prefs) {
    value = prefs.getBool(name) ?? value;
    // print("Loaded $name -> $value");
  }

  void save(SharedPreferencesWithCache prefs) {
    // print("Saving $name -> $value");
    prefs.setBool(name, value);
  }

  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [
      Text("$description: "),
      Checkbox(
          value: this.value,
          onChanged: (bool? value) {
            this.value = value!;
            rebuild();
          }),
      SizedBox(width: 10),
    ];
  }
}

class SavableDouble extends Savable<double> {
  TextEditingController? _controller;

  SavableDouble(super.name, super.description, super.value, {super.tip = ""});
  void load(SharedPreferencesWithCache prefs) {
    value = prefs.getDouble(name) ?? value;
    // print("Loaded $name -> $value");
  }

  void save(SharedPreferencesWithCache prefs) {
    try {
      if (_controller != null) {
        value = double.parse(_controller!.text);
      }
    } catch (ex) {
      print("Parse error in ${_controller!.text} for $name");
    }
    // print("Saving $name -> $value");
    prefs.setDouble(name, value);
  }

  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    // print("Building widget for $name");
    _controller = TextEditingController();
    _controller!.text = value.toString();
    return [
      Text("$description: "),
      Flexible(
          child: TextField(
              controller: _controller,
              // style: TextStyle(fontSize: 10),
              decoration: InputDecoration(hintText: tip))),
      SizedBox(width: 10),
    ];
  }

  void dispose() {
    // print("Disposing of widget for $name");
    _controller?.dispose();
    _controller = null;
  }
}

// Add an EndOfRow to the settings to
class EndOfRow extends Savable<int> {
  static int count = 0;
  EndOfRow() : super("row $count", "UI Feature", count++);

  void load(SharedPreferencesWithCache prefs) {}
  void save(SharedPreferencesWithCache prefs) {}

  // For building a UI.
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [null];
  }
}

class Settings {
  static Settings _singleton = Settings();
  static Settings get instance => _singleton;

  SettingsStatus _status = SettingsStatus.NotInitialized;
  final StreamController<SettingsStatus> _statusStream =
      StreamController<SettingsStatus>.broadcast();

  String app_name = "uninitialized";
  String version = "uninitialized";
  String build_number = "-";
  bool no_keyboard = false;
  Future<void>? _loading_future = null;

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

  SettingsStatus get status {
    return _status;
  }

  void set status(SettingsStatus newStatus) {
    this._status = newStatus;
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
    if (_loading_future == null) {
      _loading_future = _load_future();
    }
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
    await dsleep("settings", 3);
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    app_name = packageInfo.appName;
    version = packageInfo.version;
    build_number = packageInfo.buildNumber;
    // print("Package info: $app_name, $build_number, $version");
    var prefs = await getPrefs();
    // print("prefs = $prefs");
    // theme.load(prefs);
    for (var s in savables) {
      s.load(prefs);
    }
    // print("Settings done initialized.");
    status = SettingsStatus.Initialized;
    _loading_future = null;
    // print("Finished loading settings.");
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
  SettingsScreen({super.key});
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
      return Text("Initiaizing Settings...");
    }
    // print("Building SettingsScreen.");
    List<Widget?> children = _pickChildren(context);
    List<List<Widget>> rows = [for (var s in MyIterator(children)) s];
    final list = ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: rows.length,
      itemBuilder: (buildContext, int index) {
        return Container(
          // height: 50,
          child: Row(
            children: rows[index],
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
    return MaterialApp(
      // XXX debugShowCheckedModeBanner: false,
      theme: Settings.instance.theme.theme_data,
      home: Scaffold(
        appBar: appBar(context),
        body: list,
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: Text("Settings"),
      actions: <Widget>[
        ElevatedButton(
          child: const Icon(Icons.close),
          onPressed: () {
            // print("Cancel.");
            quit(context);
          },
        ),
        ElevatedButton(
          child: const Icon(Icons.done),
          onPressed: () {
            // print("Done.");
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
      return [Text("Initializing App...")];
    }
    List<List<Widget?>> list1 = [
      [
        SelectableText("Application ${Settings.instance.app_name} "
            "version ${Settings.instance.version}.${Settings.instance.build_number}"),
        null,
      ],
      for (var s in Settings.instance.savables)
        if (s.visible)
          (s.build(context, () {
            setState(() {});
          })),
      [
        null,
        ElevatedButton(
          onPressed: () => done(context),
          child: Text("Done"),
        ),
        ElevatedButton(
          onPressed: () => quit(context),
          child: Text("Cancel"),
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
  List<Widget> get current => _current;
  Iterator<List<Widget>> get iterator => this;

  MyIterator(this.input);

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
