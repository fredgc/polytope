import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('lt'),
    Locale('pt'),
    Locale('zh')
  ];

  /// Tab label for the About screen in help
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTab;

  /// Title of the application
  ///
  /// In en, this message translates to:
  /// **'Polytope Demo'**
  String get appTitle;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Tooltip for close buttons
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// Title for color picker dialog
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get colorPickerTitle;

  /// Tab label for the Controls documentation
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get controlsTab;

  /// Tooltip for debug button
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debugTooltip;

  /// Tooltip for decreasing slider speed
  ///
  /// In en, this message translates to:
  /// **'Decrease speed'**
  String get decreaseSpeedTooltip;

  /// Short label for dimension button on app bar
  ///
  /// In en, this message translates to:
  /// **'Dim {dim}'**
  String dimButtonLabel(int dim);

  /// Menu item label for selecting a dimension
  ///
  /// In en, this message translates to:
  /// **'Dimension {dim}'**
  String dimensionMenuLabel(int dim);

  /// Done button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// Tooltip for save and close button
  ///
  /// In en, this message translates to:
  /// **'Save and close'**
  String get doneTooltip;

  /// Title of the Help screen
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// Tooltip for help button
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTooltip;

  /// Tooltip for increasing slider speed
  ///
  /// In en, this message translates to:
  /// **'Increase speed'**
  String get increaseSpeedTooltip;

  /// Status text while initializing application
  ///
  /// In en, this message translates to:
  /// **'Initializing App...'**
  String get initializingApp;

  /// Status text while initializing settings
  ///
  /// In en, this message translates to:
  /// **'Initializing Settings...'**
  String get initializingSettings;

  /// Option to use system locale
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// Text displayed while web content is loading
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingText;

  /// Camera movement mode: Rotate in 3D
  ///
  /// In en, this message translates to:
  /// **'Rotate R3'**
  String get movementRotate3;

  /// Tooltip for 3D rotation mode
  ///
  /// In en, this message translates to:
  /// **'Mouse drags will rotate the polytope in R3'**
  String get movementRotate3Tip;

  /// Camera movement mode: Rotate in 4D
  ///
  /// In en, this message translates to:
  /// **'Rotate R4'**
  String get movementRotate4;

  /// Tooltip for 4D rotation mode
  ///
  /// In en, this message translates to:
  /// **'Mouse drags will rotate the polytope in R4'**
  String get movementRotate4Tip;

  /// Camera movement mode: Rotate in 5D
  ///
  /// In en, this message translates to:
  /// **'Rotate R5'**
  String get movementRotate5;

  /// Tooltip for 5D rotation mode
  ///
  /// In en, this message translates to:
  /// **'Mouse drags will rotate the polytope in R5'**
  String get movementRotate5Tip;

  /// Camera movement mode: Scale
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get movementScale;

  /// Tooltip for scale mode
  ///
  /// In en, this message translates to:
  /// **'Mouse drags will make the polytope larger or smaller'**
  String get movementScaleTip;

  /// Camera movement mode: Translate
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get movementTranslate;

  /// Tooltip for translation mode
  ///
  /// In en, this message translates to:
  /// **'Mouse drags will move or translate the polytope'**
  String get movementTranslateTip;

  /// Camera movement mode: Zolly
  ///
  /// In en, this message translates to:
  /// **'Zolly'**
  String get movementZolly;

  /// Tooltip for zolly mode
  ///
  /// In en, this message translates to:
  /// **'Zolly = zoom + dolly. Mouse drags will change the perspective.'**
  String get movementZollyTip;

  /// Tab label for the overview documentation
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// Name of the 120-cell regular polychoron
  ///
  /// In en, this message translates to:
  /// **'120 Cell'**
  String get polytopeCell120;

  /// Name of the 24-cell regular polychoron
  ///
  /// In en, this message translates to:
  /// **'24 Cell'**
  String get polytopeCell24;

  /// Name of the 600-cell regular polychoron
  ///
  /// In en, this message translates to:
  /// **'600 Cell'**
  String get polytopeCell600;

  /// Name of the cross-polytope / orthoplex
  ///
  /// In en, this message translates to:
  /// **'Cross Type'**
  String get polytopeCross;

  /// Name of the hypercube / cube
  ///
  /// In en, this message translates to:
  /// **'Cube'**
  String get polytopeCube;

  /// Name of the dodecahedron
  ///
  /// In en, this message translates to:
  /// **'Dodecahedron'**
  String get polytopeDodec;

  /// Name of the icosahedron
  ///
  /// In en, this message translates to:
  /// **'Icosahedron'**
  String get polytopeIco;

  /// Name of the regular simplex
  ///
  /// In en, this message translates to:
  /// **'Simplex'**
  String get polytopeSimplex;

  /// Tab label for the privacy policy documentation
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTab;

  /// Application version information text
  ///
  /// In en, this message translates to:
  /// **'Application {appName} version {version}.{buildNumber}'**
  String settingAppVersion(String appName, String version, String buildNumber);

  /// Label for background color setting
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get settingBackgroundColor;

  /// Label for clipping gap size setting
  ///
  /// In en, this message translates to:
  /// **'Clipping Gap Size'**
  String get settingClipGapSize;

  /// Label for debug logs setting
  ///
  /// In en, this message translates to:
  /// **'Periodic Debug Logs'**
  String get settingDebugLogs;

  /// Label for enable line clipping setting
  ///
  /// In en, this message translates to:
  /// **'Clip Crossing Lines'**
  String get settingEnableLineClipping;

  /// Label for polytope color setting
  ///
  /// In en, this message translates to:
  /// **'Polytope Color'**
  String get settingPolyColor;

  /// Label for polytope edge thickness setting
  ///
  /// In en, this message translates to:
  /// **'Polytope Edge Thickness'**
  String get settingPolyEdgeThickness;

  /// Label for show hotkey buttons setting
  ///
  /// In en, this message translates to:
  /// **'Show Hotkey Buttons'**
  String get settingShowHotkeyButtons;

  /// Label for slice color setting
  ///
  /// In en, this message translates to:
  /// **'Slice Color'**
  String get settingSliceColor;

  /// Label for slice edge thickness setting
  ///
  /// In en, this message translates to:
  /// **'Slice Edge Thickness'**
  String get settingSliceEdgeThickness;

  /// Label for sticky delay setting
  ///
  /// In en, this message translates to:
  /// **'Sticky delay'**
  String get settingStickyDelay;

  /// Label for sticky radius setting
  ///
  /// In en, this message translates to:
  /// **'Sticky radius'**
  String get settingStickyRadius;

  /// Label for theme brightness setting
  ///
  /// In en, this message translates to:
  /// **'Theme Brightness'**
  String get settingThemeBrightness;

  /// Label for theme color setting
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get settingThemeColor;

  /// Label for vertex size setting
  ///
  /// In en, this message translates to:
  /// **'Vertex Size'**
  String get settingVertexRadius;

  /// Title of the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Tooltip for settings button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// Tooltip for showing the slice checkbox
  ///
  /// In en, this message translates to:
  /// **'Show slice'**
  String get showSliceTooltip;

  /// Label next to the slice checkbox
  ///
  /// In en, this message translates to:
  /// **'slice:'**
  String get sliceLabel;

  /// Tab label for the Slices documentation
  ///
  /// In en, this message translates to:
  /// **'Slices'**
  String get slicesTab;

  /// Label for the hyperplane slice slider
  ///
  /// In en, this message translates to:
  /// **'Slice'**
  String get sliderSlice;

  /// Rotation snap: 3-cell in front
  ///
  /// In en, this message translates to:
  /// **'3-Cell first'**
  String get snapCell;

  /// Tooltip for 3-cell first rotation snap
  ///
  /// In en, this message translates to:
  /// **'Rotate polytope so a 3-cell is in front'**
  String get snapCellTip;

  /// Rotation snap: edge in front
  ///
  /// In en, this message translates to:
  /// **'Edge first'**
  String get snapEdge;

  /// Tooltip for edge first rotation snap
  ///
  /// In en, this message translates to:
  /// **'Rotate polytope so an edge is in front'**
  String get snapEdgeTip;

  /// Rotation snap: face in front
  ///
  /// In en, this message translates to:
  /// **'Face first'**
  String get snapFace;

  /// Tooltip for face first rotation snap
  ///
  /// In en, this message translates to:
  /// **'Rotate polytope so a face is in front'**
  String get snapFaceTip;

  /// Rotation snap: vertex in front
  ///
  /// In en, this message translates to:
  /// **'Vertex first'**
  String get snapVertex;

  /// Tooltip for vertex first rotation snap
  ///
  /// In en, this message translates to:
  /// **'Rotate polytope so a vertex is in front'**
  String get snapVertexTip;

  /// Tooltip for language switcher popup menu
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguageTooltip;

  /// Tooltip for switching to augmented reality mode
  ///
  /// In en, this message translates to:
  /// **'Switch to AR mode'**
  String get switchToArTooltip;

  /// Tab label for terms of service documentation
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsTab;

  /// Dark theme mode option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// Light theme mode option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// System default theme mode option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'ja',
        'lt',
        'pt',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'lt':
      return AppLocalizationsLt();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
