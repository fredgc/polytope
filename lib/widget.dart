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
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import 'animate.dart';
import 'help.dart';
import 'l10n/l10n_extension.dart';
import 'regular.dart';
import 'scene.dart';
import 'settings.dart';
import 'slider.dart';
import 'xr_support.dart';

class PolyAppWidget extends StatefulWidget {
  static const routeName = "/";
  final XRSupport xr;

  PolyAppWidget(this.xr, {super.key}) {
    print("YELLOW: Create new PolyAppWidget.");
  }

  @override
  State<PolyAppWidget> createState() => PolyAppWidgetState();
}

class PolyAppWidgetState extends State<PolyAppWidget>
    with SingleTickerProviderStateMixin {
  Scene scene;
  bool use_xr = false;

  late StreamSubscription _statusListener;
  late final MyAnimator animator; // Created in init state.
  BoxConstraints _constraints = BoxConstraints();
  bool _narrow = false;

  late final Timer debug_timer;
  int timer_counter = 0;
  static int poly_count = 0;
  int poly_number = 0;
  int build_count = 0;

  PolyAppWidgetState() : scene = Scene();

  static SavableBool debug_logs = SavableBool(
      "debug_logs", "Periodic Debug Logs", false,
      tip: "Print some debug logs to the console.");

  static void initSettings(Settings settings) {
    settings.addTheme();
    Scene.initSettings(settings);
    MySlider.initSettings(settings);
    settings.add(EndOfRow());
    settings.add(debug_logs);
  }

  void updateSettings() {
    scene.updateSettings();
  }

  @override
  void initState() {
    super.initState();
    print("RED: PolyAppWidget initState.");
    widget.xr.scene = scene;
    widget.xr.onExitXR = () {
      if (mounted) {
        setState(() {
          use_xr = false;
        });
      }
    };
    _statusListener = Settings.instance.statusStream().listen((status) {
      setState(() {
        // print("YELLOW: Widget setting state based on status $status");
        updateSettings();
        scene.updateList(); // Update the colors.
      });
    });
    animator = MyAnimator(this, scene);
    scene.startAnimation = startAnimation;
    // print("Settings speed = ${Settings.instance.speed}");
    debug_timer = makeTimer();
    HardwareKeyboard.instance.addHandler(keyHandler);
  }

  Timer makeTimer() {
    poly_count++;
    poly_number = poly_count;
    return Timer.periodic(const Duration(seconds: 5), (timer) {
      if (debug_logs.value) {
        timer_counter++;
        print(
            "T$poly_number $timer_counter, b$build_count, ${scene.debugPrint()}${animator.debugPrint()}");
      }
    });
  }

  void startAnimation() {
    // print("GREEN: Widget heard startAnimation.");
    animator.play();
  }

  @override
  void dispose() {
    // print("RED: Displose of widget.");
    _statusListener.cancel();
    debug_timer.cancel();
    HardwareKeyboard.instance.removeHandler(keyHandler);
    animator.dispose();
    scene.dispose();
    super.dispose();
  }

  bool keyHandler(KeyEvent event) {
    if (scene.keyHandle(event.character)) {
      // print("Key changed event: $event");
      setState(() {
        // print("Key changed.");
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    build_count++;
    // This happens on every state change, including slider updates.
    // print("YELLOW: PolyAppWidget build.");
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      // If the constraints have changed, then we want to try the wide layout again.
      // If not then keep the previous state of _narrow.
      if (constraints != _constraints) {
        _narrow = false;
        _constraints = constraints;
      }
      return Theme(
        data: Settings.instance.theme.theme_data,
        child: Scaffold(
          appBar: makeAppBar(context),
          body: SafeArea(
            child: Center(
              child: Builder(
                // This makes all the children use my theme.
                builder: (BuildContext c) => _centerWidget(c),
              ),
            ),
          ),
        ),
      );
    });
  }

  AppBar makeAppBar(BuildContext context) {
    final settingsButton = IconButton(
      onPressed: () {
        Navigator.pushNamed(context, SettingsScreen.routeName);
      },
      icon: const Icon(Icons.settings),
      tooltip: context.l10n.settingsTooltip,
    );

    return AppBar(
      title: _buildPolyMenu(context),
      leading: settingsButton,
      actions: _getButtons(context),
    );
  }

  Widget _buildPolyMenu(BuildContext context) {
    return MenuAnchor(
        menuChildren: Regular.values
            .map((poly) => MenuItemButton(
                  child: Text(poly.localizedName(context)),
                  onPressed: () {
                    if (poly != scene.type) {
                      setState(() {
                        scene.setPolytope(poly);
                      });
                    }
                  },
                ))
            .toList(),
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return TextButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: _polyTitle(context),
          );
        });
  }

  // Make a text widget that might be truncated. If the text is truncated, then
  // we want to switch to the narrow layout.
  Widget _polyTitle(BuildContext context) {
    final title = scene.type.localizedName(context);
    return LayoutBuilder(builder: (context, size) {
      var tp = TextPainter(
        maxLines: 1,
        textDirection: TextDirection.ltr,
        text: TextSpan(text: title),
      );
      tp.layout(maxWidth: size.maxWidth);
      var exceeded = tp.didExceedMaxLines;
      if (exceeded) {
        if (!_narrow) {
          // Wait until this build/layout is finished and then try again with
          // a narrow layout.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _narrow = true;
            });
          });
        }
      }
      return Text(
        title,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      );
    });
  }

  List<Widget> _getButtons(BuildContext context) {
    // print("Get buttons.");
    List<Widget> list = [];
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    if (!_narrow && !isCompact) _getOtherButtons(list, context);
    if (widget.xr.supported && !kReleaseMode) {
      list.add(
          _makeButton(context.l10n.switchToArTooltip, Icons.view_in_ar, () {
        print("RED: switch to XR.");
        widget.xr.switchToXR().then((bool itWorked) {
          print("it_worked = $itWorked");
          setState(() {
            use_xr = widget.xr.supported && widget.xr.isActive;
          });
        });
      }));
    }
    list.add(_makeButton(context.l10n.helpTooltip, Icons.help, () {
      Navigator.pushNamed(context, HelpScreen.routeName);
    }));
    if (debug_logs.value) {
      list.add(_makeButton(context.l10n.debugTooltip, Icons.info, () {
        scene.dumpDebugInfo();
      }));
    }
    list.add(_buildLanguageSwitcher(context));
    return list;
  }

  Widget _buildLanguageSwitcher(BuildContext context) {
    return const LanguageMenuButton();
  }

  void _getOtherButtons(List<Widget> list, BuildContext context) {
    list.add(_pickDim(context));
    list.add(_sliceControl(context));
    list.add(scene.buildMovementMenu(context, this));
  }

  Widget _makeButton(String tip, IconData data, VoidCallback callback) {
    return IconButton(
      icon: Icon(data),
      tooltip: tip,
      onPressed: () {
        // setState(() {
        callback();
        // });
      },
    );
  }

  Widget _pickDim(BuildContext context) {
    // print("Pick dim. current = ${scene.polytope.dim}");
    return MenuAnchor(
        menuChildren: [
          for (var i = Regular.min_dim; i <= Regular.max_dim; i++)
            MenuItemButton(
              child: Text(context.l10n.dimensionMenuLabel(i)),
              onPressed: () {
                if (i != scene.polytope.dim) {
                  setState(() {
                    // print("Changing dim to $i.");
                    scene.setDim(i);
                  });
                }
              },
            )
        ],
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return TextButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Text(context.l10n.dimButtonLabel(scene.polytope.dim)),
          );
        });
  }

  Widget _sliceControl(BuildContext context) {
    return Tooltip(
        message: context.l10n.showSliceTooltip,
        waitDuration: const Duration(seconds: 3),
        child: Row(children: <Widget>[
          Text(context.l10n.sliceLabel),
          Checkbox(
              value: scene.slice_active,
              onChanged: (bool? value) {
                setState(() {
                  scene.changeSlice(value!);
                });
              }),
        ]));
  }

  Widget _centerWidget(BuildContext context) {
    if (Settings.instance.status == SettingsStatus.NotInitialized) {
      Settings.instance.initialize(context);
      return Text(context.l10n.initializingSettings);
    }
    if (use_xr) {
      print("BLUE: building xr widget.");
      return widget.xr.buildScene(context);
    }

    List<Widget> column = [];
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    if (_narrow || isCompact) {
      List<Widget> list = [];
      _getOtherButtons(list, context);
      column.add(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: list),
        ),
      );
    }
    column.add(Expanded(child: mainViewWidget(context)));
    if (scene.slice != null) {
      column.add(scene.slice!.slider.build(context));
    }
    return Column(children: column);
  }

  Widget mainViewWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Settings.instance.background_color,
        border: Border.all(
          width: 2.0,
          color: Settings.instance.theme.scheme.outline,
        ),
      ),
      child: ClipRect(child: scene.build(context, this)),
    );
  }
}
