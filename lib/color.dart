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

import 'l10n/l10n_extension.dart';
import 'settings.dart';

class SavableColor extends Savable<Color> {
  final Color Function(ColorScheme) reset;
  // This is called when the color changes.
  VoidCallback? callback;

  SavableColor(super.name, super.description, super.value, this.reset);

  @override
  void load(SharedPreferencesWithCache prefs) {
    // print("Loading $name as ${prefs.getInt(name)}");
    value = Color(prefs.getInt(name) ?? value.toARGB32());
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    // print("Saving $name as ${value.value}");
    prefs.setInt(name, value.toARGB32());
  }

  // This is called when the theme changes.
  @override
  void updateTheme(ColorScheme scheme) {
    // Color old = value;
    value = reset(scheme);
    // print("updating color for $name from $old to $value");
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    if (Settings.instance.is_android_tv) {
      return [
        _TvSettingRow(
          label: localizedName(context),
          onActivate: () async {
            await pickColor(context);
            callback?.call();
            rebuild();
          },
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1.5,
              ),
            ),
          ),
        ),
      ];
    }
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(child: Text('${localizedName(context)}: ')),
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
        ],
      ),
    ];
  }

  Future<void> pickColor(BuildContext context) async {
    if (Settings.instance.is_android_tv) {
      final Color? picked = await showTvColorPickerDialog(context, value);
      if (picked != null) {
        value = picked;
        callback?.call();
      }
      return;
    }
    // Just for debugging: Color original = value;
    final Color newColor = await showColorPickerDialog(
      // The dialog needs a context, we pass it in.
      context,
      // We use the dialogSelectColor, as its starting color.
      value,
      title: Text(context.l10n.colorPickerTitle,
          style: Theme.of(context).textTheme.titleLarge),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 0,
      wheelDiameter: 165,
      enableOpacity: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: Settings.instance.is_android_tv
          ? const <ColorPickerType, bool>{
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.wheel: false,
            }
          : const <ColorPickerType, bool>{
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

  @override
  void load(SharedPreferencesWithCache prefs) {
    for (int i = 0; i < value.length; i++) {
      String key = "$name $i";
      // print("Loading '$key' as ${prefs.getInt(key)}");
      value[i] = Color(prefs.getInt(key) ?? value[i].toARGB32());
    }
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    for (int i = 0; i < value.length; i++) {
      String key = "$name $i";
      // print("Saving $key as ${value[i].value}");
      prefs.setInt(key, value[i].toARGB32());
    }
  }

  // This is called when the theme changes.
  @override
  void updateTheme(ColorScheme scheme) {
    // print("Update theme for $name. using scheme.brightness = ${scheme.brightness}");
    value = reset(scheme);
  }

  @override
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
    if (Settings.instance.is_android_tv) {
      final Color? picked = await showTvColorPickerDialog(context, value[i]);
      if (picked != null) {
        value[i] = picked;
      }
      return;
    }
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
      pickersEnabled: Settings.instance.is_android_tv
          ? const <ColorPickerType, bool>{
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.wheel: false,
            }
          : const <ColorPickerType, bool>{
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
      "theme_color", "Theme Color", Colors.purple, (scheme) => scheme.primary);
  SavableColor background_color = SavableColor("backgroud_color",
      "Background Color", Colors.black, (scheme) => scheme.surface);
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

  @override
  void load(SharedPreferencesWithCache prefs) {
    try {
      theme_mode =
          ThemeMode.values[prefs.getInt("theme_mode") ?? theme_mode.index];
      // print("Theme mode = $theme_mode");
    } catch (e) {
      // print("Bad theme value? ${prefs.getInt("theme_mode")}");
    }
    theme_color.load(prefs);
    update();
    background_color.load(prefs);
  }

  @override
  void save(SharedPreferencesWithCache prefs) {
    // // print("Setting theme_mode as ${theme_mode.index}");
    prefs.setInt("theme_mode", theme_mode.index);
    theme_color.save(prefs);
    background_color.save(prefs);
  }

  // Called by settings to update all of the savables.
  @override
  void updateTheme(ColorScheme scheme) {
    // print("--- Updating theme for theme.");
    update();
  }

  // Update the colors based on the theme color.
  void update({bool resetBackground = true}) {
    Brightness brightness = _sys_brightness;
    if (theme_mode == ThemeMode.light) brightness = Brightness.light;
    if (theme_mode == ThemeMode.dark) brightness = Brightness.dark;
    // print("update theme from color ${theme_color.value}, brightness=$brightness.");
    _scheme = ColorScheme.fromSeed(
        seedColor: theme_color.value, brightness: brightness);
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: _scheme.primary, width: 2.5);
      }
      return null;
    });
    theme_data = ThemeData(
      colorScheme: _scheme,
      scaffoldBackgroundColor: _scheme.surface,
      focusColor: _scheme.primary.withValues(alpha: 0.3),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _scheme.primaryContainer,
          foregroundColor: _scheme.onPrimaryContainer,
        ).copyWith(side: focusSide),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(side: focusSide),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(side: focusSide),
      ),
    );
    if (resetBackground) {
      background_color.value = _scheme.surface;
    }
  }

  void updateAndCallback() {
    // print("update and callback. callback = $_callback.");
    update();
    _callback.call();
  }

  @override
  List<Widget?> build(BuildContext context, VoidCallback rebuild) {
    // Make a flattened list of all the witches in the theme colors.
    return [
      switcher(context, rebuild),
      null,
      for (var w in theme_color.build(context, rebuild)) w,
      if (Settings.instance.is_android_tv) null,
      for (var w in background_color.build(context, rebuild)) w,
      null,
    ];
  }

  Widget switcher(BuildContext context, VoidCallback callback) {
    List<bool> isSelected = List<bool>.filled(ThemeMode.values.length, false);
    isSelected[theme_mode.index] = true;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        Text('${context.l10n.settingThemeBrightness}: '),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ToggleButtons(
            isSelected: isSelected,
            onPressed: (int index) {
              // print("Setting theme_mode to $index");
              theme_mode = ThemeMode.values[index];
              // TODO: this actually calls update several times.
              // print("switcher changed.");
              updateAndCallback();
              callback();
            },
            children: [
              Text(context.l10n.themeModeSystem),
              Text(context.l10n.themeModeLight),
              Text(context.l10n.themeModeDark),
            ],
          ),
        ),
      ],
    );
  }
}

const List<Color> _tvColorPalette = <Color>[
  Colors.white,
  Color(0xFFD0D0D0),
  Colors.grey,
  Color(0xFF424242),
  Color(0xFF1A1A1A),
  Colors.black,
  Colors.red,
  Colors.redAccent,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Color(0xFFFF8A80),
  Color(0xFFEA80FC),
  Color(0xFF82B1FF),
  Color(0xFF80D8FF),
  Color(0xFFB9F6CA),
  Color(0xFFFFFF8D),
];

/// D-pad friendly color chooser dialog for Android TV.
Future<Color?> showTvColorPickerDialog(
    BuildContext context, Color currentColor) {
  int initialIndex = _tvColorPalette
      .indexWhere((c) => c.toARGB32() == currentColor.toARGB32());
  if (initialIndex < 0) initialIndex = 0;

  return showDialog<Color>(
    context: context,
    builder: (BuildContext dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(dialogContext.l10n.colorPickerTitle),
        content: SizedBox(
          width: 396,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _tvColorPalette.length,
            itemBuilder: (BuildContext context, int index) {
              final swatch = _tvColorPalette[index];
              final isSelected = swatch.toARGB32() == currentColor.toARGB32();
              final checkColor = ThemeData.estimateBrightnessForColor(swatch) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black;
              return _TvColorSwatchButton(
                color: swatch,
                isSelected: isSelected,
                checkColor: checkColor,
                focusBorderColor: scheme.primary,
                autofocus: index == initialIndex,
                onSelect: () => Navigator.of(dialogContext).pop(swatch),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(dialogContext.l10n.cancelButton),
          ),
        ],
      );
    },
  );
}

class _TvColorSwatchButton extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final Color checkColor;
  final Color focusBorderColor;
  final bool autofocus;
  final VoidCallback onSelect;

  const _TvColorSwatchButton({
    required this.color,
    required this.isSelected,
    required this.checkColor,
    required this.focusBorderColor,
    required this.autofocus,
    required this.onSelect,
  });

  @override
  State<_TvColorSwatchButton> createState() => _TvColorSwatchButtonState();
}

class _TvColorSwatchButtonState extends State<_TvColorSwatchButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      autofocus: widget.autofocus,
      borderRadius: BorderRadius.circular(28),
      onFocusChange: (focused) => setState(() => _focused = focused),
      onTap: widget.onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _focused
                ? widget.focusBorderColor
                : Theme.of(context).colorScheme.outline,
            width: _focused ? 4.0 : 1.5,
          ),
        ),
        child: widget.isSelected
            ? Icon(Icons.check, color: widget.checkColor, size: 24)
            : null,
      ),
    );
  }
}

class _TvSettingRow extends StatefulWidget {
  final String label;
  final Widget trailing;
  final VoidCallback onActivate;

  const _TvSettingRow({
    required this.label,
    required this.trailing,
    required this.onActivate,
  });

  @override
  State<_TvSettingRow> createState() => _TvSettingRowState();
}

class _TvSettingRowState extends State<_TvSettingRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onFocusChange: (focused) => setState(() => _focused = focused),
        onTap: widget.onActivate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ExcludeFocus(child: widget.trailing),
            ],
          ),
        ),
      ),
    );
  }
}
