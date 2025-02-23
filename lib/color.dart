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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

import 'settings.dart';

class SavableColor extends Savable<Color> {
  final Color Function(ColorScheme) reset;
  // This is called when the color changes.
  VoidCallback? callback;

  SavableColor(super.name, super.description, super.value, this.reset);

  void load(SharedPreferencesWithCache prefs) {
    // print("Loading $name as ${prefs.getInt(name)}");
    value = Color(prefs.getInt(name) ?? value.value);
  }

  void save(SharedPreferencesWithCache prefs) {
    // print("Saving $name as ${value.value}");
    prefs.setInt(name, value.value);
  }

  // This is called when the theme changes.
  void updateTheme(ColorScheme scheme) {
    // Color old = value;
    value = reset(scheme);
    // print("updating color for $name from $old to $value");
  }

  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    return [
      Text('$description: '),
      ColorIndicator(
        width: 30,
        height: 30,
        borderRadius: 15,
        color: value,
        elevation: 1,
        onSelectFocus: false,
        onSelect: () async {
          await pickColor(context);
          //print("Update $name. callback = $callback");
          callback?.call();
          rebuild();
        },
      ),
      SizedBox(width: 10),
    ];
  }

  Future<void> pickColor(BuildContext context) async {
    // Just for debugging: Color original = value;
    final Color newColor = await showColorPickerDialog(
      // The dialog needs a context, we pass it in.
      context,
      // We use the dialogSelectColor, as its starting color.
      value,
      title: Text('Pick', style: Theme.of(context).textTheme.titleLarge),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 0,
      wheelDiameter: 165,
      enableOpacity: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: <ColorPickerType, bool>{
        ColorPickerType.wheel: true,
      },
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
      ),
      actionButtons: const ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: false,
      ),
      transitionBuilder: (BuildContext context, Animation<double> a1,
          Animation<double> a2, Widget widget) {
        final double curvedValue =
            Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: widget,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      constraints:
          const BoxConstraints(minHeight: 480, minWidth: 320, maxWidth: 320),
    );
    value = newColor;
    // print("After picking $name, color=$value, original = $original");
    callback?.call();
  }
}

class SavableColorArray extends Savable<List<Color>> {
  final List<Color> Function(ColorScheme) reset;

  SavableColorArray(super.name, super.description, super.value, this.reset);

  void load(SharedPreferencesWithCache prefs) {
    for (int i = 0; i < value.length; i++) {
      String key = "$name $i";
      // print("Loading '$key' as ${prefs.getInt(key)}");
      value[i] = Color(prefs.getInt(key) ?? value[i].value);
    }
  }

  void save(SharedPreferencesWithCache prefs) {
    for (int i = 0; i < value.length; i++) {
      String key = "$name $i";
      // print("Saving $key as ${value[i].value}");
      prefs.setInt(key, value[i].value);
    }
  }

  // This is called when the theme changes.
  void updateTheme(ColorScheme scheme) {
    // print("Update theme for $name. using scheme.brightness = ${scheme.brightness}");
    value = reset(scheme);
  }

  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    List<Widget> children = [];
    children.add(Text('$description: '));
    for (int i = 0; i < value.length; i++) {
      children.add(ColorIndicator(
        width: 30,
        height: 30,
        borderRadius: 15,
        color: value[i],
        elevation: 1,
        onSelectFocus: false,
        onSelect: () async {
          await pickColor(context, i);
          rebuild();
        },
      ));
    }
    children.add(SizedBox(width: 10));
    return children;
  }

  Future<void> pickColor(BuildContext context, int i) async {
    // Just for debugging: Color original = value[i];
    // print("Picking color for $name $i");

    final Color newColor = await showColorPickerDialog(
      // The dialog needs a context, we pass it in.
      context,
      // We use the dialogSelectColor, as its starting color.
      value[i],
      title:
          Text('Pick $name $i', style: Theme.of(context).textTheme.titleLarge),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 0,
      wheelDiameter: 165,
      enableOpacity: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: <ColorPickerType, bool>{
        ColorPickerType.wheel: true,
      },
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
      ),
      actionButtons: const ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: false,
      ),
      transitionBuilder: (BuildContext context, Animation<double> a1,
          Animation<double> a2, Widget widget) {
        final double curvedValue =
            Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: widget,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      constraints:
          const BoxConstraints(minHeight: 480, minWidth: 320, maxWidth: 320),
    );
    value[i] = newColor;
    // print("After picking $name $i, color=$newColor, original = $original");
  }
}

class SavableTheme extends Savable<int> {
  late VoidCallback _callback;

  Brightness _sys_brightness = Brightness.light;
  SavableColor theme_color = SavableColor(
      "theme_color", "Theme Color", Colors.purple, (scheme) => Colors.red);
  SavableColor background_color = SavableColor("backgroud_color",
      "Background Color", Colors.black, (scheme) => Colors.red);
  ColorScheme _scheme = ColorScheme.light();
  ThemeMode theme_mode = ThemeMode.system;
  ThemeData theme_data = ThemeData.light();

  ColorScheme get scheme => _scheme;

  SavableTheme() : super("theme", "The color theme", Brightness.light.index);

  // This is called once when Settings is initialized. It uses the context to
  // figure out what the system default for brightness is.
  void initialize(VoidCallback callback, BuildContext context) {
    _callback = callback;
    _sys_brightness = MediaQuery.of(context).platformBrightness;
    // TODO: this calls update a few times when the color changes.
    theme_color.callback = updateAndCallback;
    // Call update to generate some default colors first, before we can load.
    update();
    // print("Finished with theme initialize................................");
  }

  void load(SharedPreferencesWithCache prefs) {
    try {
      theme_mode =
          ThemeMode.values[prefs.getInt("theme_mode") ?? theme_mode.index];
      // print("Theme mode = $theme_mode");
    } catch (e) {
      // print("Bad theme value? ${prefs.getInt("theme_mode")}");
    }
    theme_color.load(prefs);
    background_color.load(prefs);
    update();
  }

  void save(SharedPreferencesWithCache prefs) {
    // // print("Setting theme_mode as ${theme_mode.index}");
    prefs.setInt("theme_mode", theme_mode.index);
    theme_color.save(prefs);
    background_color.save(prefs);
  }

  // Called by settings to update all of the savables.
  void updateTheme(ColorScheme scheme) {
    // print("--- Updating theme for theme.");
    update();
  }

  // Update the colors based on the theme color.
  void update() {
    Brightness brightness = _sys_brightness;
    if (theme_mode == ThemeMode.light) brightness = Brightness.light;
    if (theme_mode == ThemeMode.dark) brightness = Brightness.dark;
    // print("update theme from color ${theme_color.value}, brightness=$brightness.");
    _scheme = ColorScheme.fromSeed(
        seedColor: theme_color.value, brightness: brightness);
    theme_data = ThemeData(colorScheme: _scheme);
    background_color.value = _scheme.surface;
    // print("--- scheme.brightness = ${scheme.brightness}");
    // print("--- surface = ${scheme.surface}.");
    // print("--- onSurface = ${scheme.onSurface}.");
    // print("--- primary = ${scheme.primary}.");
    // print("--- secondary = ${scheme.secondary}.");
    // print("--- tertiary = ${scheme.tertiary}.");
  }

  void updateAndCallback() {
    // print("update and callback. callback = $_callback.");
    update();
    this._callback.call();
  }

  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    // Make a flattened list of all the witches in the theme colors.
    return [
      switcher(context, rebuild),
      null,
      for (var w in theme_color.build(context, rebuild)) w,
      for (var w in background_color.build(context, rebuild)) w,
      null,
    ];
  }

  Widget switcher(BuildContext context, VoidCallback callback) {
    List<bool> isSelected = List<bool>.filled(ThemeMode.values.length, false);
    isSelected[theme_mode.index] = true;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Theme Brightness: '),
      SizedBox(width: 10),
      ToggleButtons(
        isSelected: isSelected,
        onPressed: (int index) {
          // print("Setting theme_mode to $index");
          theme_mode = ThemeMode.values[index];
          // TODO: this actually calls update several times.
          // print("switcher changed.");
          updateAndCallback();
          callback();
        },
        children: ThemeMode.values.map((e) => Text(e.name)).toList(),
      ),
    ]);
  }
}
