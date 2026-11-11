// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutTab => 'About';

  @override
  String get appTitle => 'Polytope Demo';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get closeTooltip => 'Close';

  @override
  String get colorPickerTitle => 'Pick Color';

  @override
  String get controlsTab => 'Controls';

  @override
  String get debugTooltip => 'Debug';

  @override
  String get decreaseSpeedTooltip => 'Decrease speed';

  @override
  String dimButtonLabel(int dim) {
    return 'Dim $dim';
  }

  @override
  String dimensionMenuLabel(int dim) {
    return 'Dimension $dim';
  }

  @override
  String get doneButton => 'Done';

  @override
  String get doneTooltip => 'Save and close';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpTooltip => 'Help';

  @override
  String get increaseSpeedTooltip => 'Increase speed';

  @override
  String get initializingApp => 'Initializing App...';

  @override
  String get initializingSettings => 'Initializing Settings...';

  @override
  String get languageAuto => 'Auto';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get loadingText => 'Loading...';

  @override
  String get movementRotate3 => 'Rotate R3';

  @override
  String get movementRotate3Tip => 'Mouse drags will rotate the polytope in R3';

  @override
  String get movementRotate4 => 'Rotate R4';

  @override
  String get movementRotate4Tip => 'Mouse drags will rotate the polytope in R4';

  @override
  String get movementRotate5 => 'Rotate R5';

  @override
  String get movementRotate5Tip => 'Mouse drags will rotate the polytope in R5';

  @override
  String get movementScale => 'Scale';

  @override
  String get movementScaleTip =>
      'Mouse drags will make the polytope larger or smaller';

  @override
  String get movementTranslate => 'Translate';

  @override
  String get movementTranslateTip =>
      'Mouse drags will move or translate the polytope';

  @override
  String get movementZolly => 'Zolly';

  @override
  String get movementZollyTip =>
      'Zolly = zoom + dolly. Mouse drags will change the perspective.';

  @override
  String get overviewTab => 'Overview';

  @override
  String get polytopeCell120 => '120 Cell';

  @override
  String get polytopeCell24 => '24 Cell';

  @override
  String get polytopeCell600 => '600 Cell';

  @override
  String get polytopeCross => 'Cross Type';

  @override
  String get polytopeCube => 'Cube';

  @override
  String get polytopeDodec => 'Dodecahedron';

  @override
  String get polytopeIco => 'Icosahedron';

  @override
  String get polytopeSimplex => 'Simplex';

  @override
  String get privacyTab => 'Privacy';

  @override
  String settingAppVersion(String appName, String version, String buildNumber) {
    return 'Application $appName version $version.$buildNumber';
  }

  @override
  String get settingBackgroundColor => 'Background Color';

  @override
  String get settingClipGapSize => 'Clipping Gap Size';

  @override
  String get settingDebugLogs => 'Periodic Debug Logs';

  @override
  String get settingEnableLineClipping => 'Clip Crossing Lines';

  @override
  String get settingPolyColor => 'Polytope Color';

  @override
  String get settingPolyEdgeThickness => 'Polytope Edge Thickness';

  @override
  String get settingShowHotkeyButtons => 'Show Hotkey Buttons';

  @override
  String get settingSliceColor => 'Slice Color';

  @override
  String get settingSliceEdgeThickness => 'Slice Edge Thickness';

  @override
  String get settingStickyDelay => 'Sticky delay';

  @override
  String get settingStickyRadius => 'Sticky radius';

  @override
  String get settingThemeBrightness => 'Theme Brightness';

  @override
  String get settingThemeColor => 'Theme Color';

  @override
  String get settingVertexRadius => 'Vertex Size';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get showSliceTooltip => 'Show slice';

  @override
  String get sliceLabel => 'slice:';

  @override
  String get slicesTab => 'Slices';

  @override
  String get sliderSlice => 'Slice';

  @override
  String get snapCell => '3-Cell first';

  @override
  String get snapCellTip => 'Rotate polytope so a 3-cell is in front';

  @override
  String get snapEdge => 'Edge first';

  @override
  String get snapEdgeTip => 'Rotate polytope so an edge is in front';

  @override
  String get snapFace => 'Face first';

  @override
  String get snapFaceTip => 'Rotate polytope so a face is in front';

  @override
  String get snapVertex => 'Vertex first';

  @override
  String get snapVertexTip => 'Rotate polytope so a vertex is in front';

  @override
  String get switchLanguageTooltip => 'Switch Language';

  @override
  String get switchToArTooltip => 'Switch to AR mode';

  @override
  String get termsTab => 'Terms';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeSystem => 'System';
}
