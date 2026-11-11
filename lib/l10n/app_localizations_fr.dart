// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get aboutTab => 'À propos';

  @override
  String get appTitle => 'Démo de polytopes';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get closeTooltip => 'Fermer';

  @override
  String get colorPickerTitle => 'Choisir une couleur';

  @override
  String get controlsTab => 'Commandes';

  @override
  String get debugTooltip => 'Débogage';

  @override
  String get decreaseSpeedTooltip => 'Diminuer la vitesse';

  @override
  String dimButtonLabel(int dim) {
    return 'Dim $dim';
  }

  @override
  String dimensionMenuLabel(int dim) {
    return 'Dimension $dim';
  }

  @override
  String get doneButton => 'Terminé';

  @override
  String get doneTooltip => 'Enregistrer et fermer';

  @override
  String get helpTitle => 'Aide';

  @override
  String get helpTooltip => 'Aide';

  @override
  String get increaseSpeedTooltip => 'Augmenter la vitesse';

  @override
  String get initializingApp => 'Initialisation de l\'application...';

  @override
  String get initializingSettings => 'Initialisation des paramètres...';

  @override
  String get languageAuto => 'Automatique';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get loadingText => 'Chargement...';

  @override
  String get movementRotate3 => 'Rotation R3';

  @override
  String get movementRotate3Tip =>
      'Glisser avec la souris fera tourner le polytope dans R3';

  @override
  String get movementRotate4 => 'Rotation R4';

  @override
  String get movementRotate4Tip =>
      'Glisser avec la souris fera tourner le polytope dans R4';

  @override
  String get movementRotate5 => 'Rotation R5';

  @override
  String get movementRotate5Tip =>
      'Glisser avec la souris fera tourner le polytope dans R5';

  @override
  String get movementScale => 'Mise à l\'échelle';

  @override
  String get movementScaleTip =>
      'Glisser avec la souris agrandira ou réduira le polytope';

  @override
  String get movementTranslate => 'Translation';

  @override
  String get movementTranslateTip =>
      'Glisser avec la souris déplacera le polytope';

  @override
  String get movementZolly => 'Zolly';

  @override
  String get movementZollyTip =>
      'Zolly = zoom + travelling. Glisser avec la souris changera la perspective.';

  @override
  String get overviewTab => 'Aperçu';

  @override
  String get polytopeCell120 => '120-cellules';

  @override
  String get polytopeCell24 => '24-cellules';

  @override
  String get polytopeCell600 => '600-cellules';

  @override
  String get polytopeCross => 'Orthoplexe';

  @override
  String get polytopeCube => 'Cube';

  @override
  String get polytopeDodec => 'Dodécaèdre';

  @override
  String get polytopeIco => 'Icosaèdre';

  @override
  String get polytopeSimplex => 'Simplexe';

  @override
  String get privacyTab => 'Confidentialité';

  @override
  String settingAppVersion(String appName, String version, String buildNumber) {
    return 'Application $appName version $version.$buildNumber';
  }

  @override
  String get settingBackgroundColor => 'Couleur d\'arrière-plan';

  @override
  String get settingClipGapSize => 'Taille de l\'écart de découpe';

  @override
  String get settingDebugLogs => 'Journaux de débogage périodiques';

  @override
  String get settingEnableLineClipping => 'Découper les lignes croisées';

  @override
  String get settingPolyColor => 'Couleur du polytope';

  @override
  String get settingPolyEdgeThickness => 'Épaisseur des arêtes du polytope';

  @override
  String get settingShowHotkeyButtons => 'Afficher les boutons de raccourci';

  @override
  String get settingSliceColor => 'Couleur de la coupe';

  @override
  String get settingSliceEdgeThickness => 'Épaisseur des arêtes de la coupe';

  @override
  String get settingStickyDelay => 'Délai d\'adhérence';

  @override
  String get settingStickyRadius => 'Rayon d\'adhérence';

  @override
  String get settingThemeBrightness => 'Luminosité du thème';

  @override
  String get settingThemeColor => 'Couleur du thème';

  @override
  String get settingVertexRadius => 'Taille des sommets';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String get showSliceTooltip => 'Afficher la coupe';

  @override
  String get sliceLabel => 'coupe :';

  @override
  String get slicesTab => 'Coupes';

  @override
  String get sliderSlice => 'Coupe';

  @override
  String get snapCell => '3-cellule devant';

  @override
  String get snapCellTip =>
      'Tourner le polytope pour placer une 3-cellule devant';

  @override
  String get snapEdge => 'Arête devant';

  @override
  String get snapEdgeTip => 'Tourner le polytope pour placer une arête devant';

  @override
  String get snapFace => 'Face devant';

  @override
  String get snapFaceTip => 'Tourner le polytope pour placer une face devant';

  @override
  String get snapVertex => 'Sommet devant';

  @override
  String get snapVertexTip =>
      'Tourner le polytope pour placer un sommet devant';

  @override
  String get switchLanguageTooltip => 'Changer de langue';

  @override
  String get switchToArTooltip => 'Passer en mode RA';

  @override
  String get termsTab => 'Conditions';

  @override
  String get themeModeDark => 'Sombre';

  @override
  String get themeModeLight => 'Clair';

  @override
  String get themeModeSystem => 'Système';
}
