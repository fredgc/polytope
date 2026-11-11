// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get aboutTab => 'Acerca de';

  @override
  String get appTitle => 'Demostración de politopos';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get closeTooltip => 'Cerrar';

  @override
  String get colorPickerTitle => 'Elegir color';

  @override
  String get controlsTab => 'Controles';

  @override
  String get debugTooltip => 'Depuración';

  @override
  String get decreaseSpeedTooltip => 'Disminuir velocidad';

  @override
  String dimButtonLabel(int dim) {
    return 'Dim $dim';
  }

  @override
  String dimensionMenuLabel(int dim) {
    return 'Dimensión $dim';
  }

  @override
  String get doneButton => 'Aceptar';

  @override
  String get doneTooltip => 'Guardar y cerrar';

  @override
  String get helpTitle => 'Ayuda';

  @override
  String get helpTooltip => 'Ayuda';

  @override
  String get increaseSpeedTooltip => 'Aumentar velocidad';

  @override
  String get initializingApp => 'Inicializando aplicación...';

  @override
  String get initializingSettings => 'Inicializando configuración...';

  @override
  String get languageAuto => 'Automático';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get loadingText => 'Cargando...';

  @override
  String get movementRotate3 => 'Rotar R3';

  @override
  String get movementRotate3Tip =>
      'Arrastrar el ratón rotará el politopo en R3';

  @override
  String get movementRotate4 => 'Rotar R4';

  @override
  String get movementRotate4Tip =>
      'Arrastrar el ratón rotará el politopo en R4';

  @override
  String get movementRotate5 => 'Rotar R5';

  @override
  String get movementRotate5Tip =>
      'Arrastrar el ratón rotará el politopo en R5';

  @override
  String get movementScale => 'Escalar';

  @override
  String get movementScaleTip =>
      'Arrastrar el ratón hará el politopo más grande o más pequeño';

  @override
  String get movementTranslate => 'Trasladar';

  @override
  String get movementTranslateTip =>
      'Arrastrar el ratón moverá o trasladará el politopo';

  @override
  String get movementZolly => 'Zolly';

  @override
  String get movementZollyTip =>
      'Zolly = zoom + dolly. Arrastrar el ratón cambiará la perspectiva.';

  @override
  String get overviewTab => 'Resumen';

  @override
  String get polytopeCell120 => '120-celdas';

  @override
  String get polytopeCell24 => '24-celdas';

  @override
  String get polytopeCell600 => '600-celdas';

  @override
  String get polytopeCross => 'Ortoplejo';

  @override
  String get polytopeCube => 'Cubo';

  @override
  String get polytopeDodec => 'Dodecaedro';

  @override
  String get polytopeIco => 'Icosaedro';

  @override
  String get polytopeSimplex => 'Símplex';

  @override
  String get privacyTab => 'Privacidad';

  @override
  String settingAppVersion(String appName, String version, String buildNumber) {
    return 'Aplicación $appName versión $version.$buildNumber';
  }

  @override
  String get settingBackgroundColor => 'Color de fondo';

  @override
  String get settingClipGapSize => 'Tamaño de espacio de recorte';

  @override
  String get settingDebugLogs => 'Registros periódicos de depuración';

  @override
  String get settingEnableLineClipping => 'Recortar líneas cruzadas';

  @override
  String get settingPolyColor => 'Color del politopo';

  @override
  String get settingPolyEdgeThickness => 'Grosor del borde del politopo';

  @override
  String get settingShowHotkeyButtons => 'Mostrar botones de atajo';

  @override
  String get settingSliceColor => 'Color del corte';

  @override
  String get settingSliceEdgeThickness => 'Grosor del borde del corte';

  @override
  String get settingStickyDelay => 'Retardo en puntos clave';

  @override
  String get settingStickyRadius => 'Radio de atracción';

  @override
  String get settingThemeBrightness => 'Brillo del tema';

  @override
  String get settingThemeColor => 'Color del tema';

  @override
  String get settingVertexRadius => 'Tamaño de vértices';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsTooltip => 'Configuración';

  @override
  String get showSliceTooltip => 'Mostrar corte';

  @override
  String get sliceLabel => 'corte:';

  @override
  String get slicesTab => 'Cortes';

  @override
  String get sliderSlice => 'Corte';

  @override
  String get snapCell => '3-celda al frente';

  @override
  String get snapCellTip =>
      'Rotar politopo para que una 3-celda quede al frente';

  @override
  String get snapEdge => 'Borde al frente';

  @override
  String get snapEdgeTip => 'Rotar politopo para que un borde quede al frente';

  @override
  String get snapFace => 'Cara al frente';

  @override
  String get snapFaceTip => 'Rotar politopo para que una cara quede al frente';

  @override
  String get snapVertex => 'Vértice al frente';

  @override
  String get snapVertexTip =>
      'Rotar politopo para que un vértice quede al frente';

  @override
  String get switchLanguageTooltip => 'Cambiar idioma';

  @override
  String get switchToArTooltip => 'Cambiar al modo RA';

  @override
  String get termsTab => 'Términos';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeSystem => 'Sistema';
}
