// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get aboutTab => 'Sobre';

  @override
  String get appTitle => 'Demonstração de Politopos';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get closeTooltip => 'Fechar';

  @override
  String get colorPickerTitle => 'Escolher Cor';

  @override
  String get controlsTab => 'Controles';

  @override
  String get debugTooltip => 'Depurar';

  @override
  String get decreaseSpeedTooltip => 'Diminuir velocidade';

  @override
  String dimButtonLabel(int dim) {
    return 'Dim $dim';
  }

  @override
  String dimensionMenuLabel(int dim) {
    return 'Dimensão $dim';
  }

  @override
  String get doneButton => 'Concluído';

  @override
  String get doneTooltip => 'Salvar e fechar';

  @override
  String get helpTitle => 'Ajuda';

  @override
  String get helpTooltip => 'Ajuda';

  @override
  String get increaseSpeedTooltip => 'Aumentar velocidade';

  @override
  String get initializingApp => 'Inicializando aplicativo...';

  @override
  String get initializingSettings => 'Inicializando configurações...';

  @override
  String get languageAuto => 'Automático';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get loadingText => 'Carregando...';

  @override
  String get movementRotate3 => 'Rotacionar R3';

  @override
  String get movementRotate3Tip => 'Arrastar o mouse girará o politopo em R3';

  @override
  String get movementRotate4 => 'Rotacionar R4';

  @override
  String get movementRotate4Tip => 'Arrastar o mouse girará o politopo em R4';

  @override
  String get movementRotate5 => 'Rotacionar R5';

  @override
  String get movementRotate5Tip => 'Arrastar o mouse girará o politopo em R5';

  @override
  String get movementScale => 'Escala';

  @override
  String get movementScaleTip =>
      'Arrastar o mouse aumentará ou diminuirá o politopo';

  @override
  String get movementTranslate => 'Transladar';

  @override
  String get movementTranslateTip => 'Arrastar o mouse moverá o politopo';

  @override
  String get movementZolly => 'Zolly';

  @override
  String get movementZollyTip =>
      'Zolly = zoom + dolly. Arrastar o mouse mudará a perspectiva.';

  @override
  String get overviewTab => 'Visão Geral';

  @override
  String get polytopeCell120 => '120-células';

  @override
  String get polytopeCell24 => '24-células';

  @override
  String get polytopeCell600 => '600-células';

  @override
  String get polytopeCross => 'Ortoplexo';

  @override
  String get polytopeCube => 'Cubo (hipercubo)';

  @override
  String get polytopeDodec => 'Dodecaedro';

  @override
  String get polytopeIco => 'Icosaedro';

  @override
  String get polytopeSimplex => 'Simplex';

  @override
  String get privacyTab => 'Privacidade';

  @override
  String settingAppVersion(String appName, String version, String buildNumber) {
    return 'Aplicativo $appName versão $version.$buildNumber';
  }

  @override
  String get settingBackgroundColor => 'Cor de Fundo';

  @override
  String get settingClipGapSize => 'Tamanho do Espaço de Recorte';

  @override
  String get settingDebugLogs => 'Logs Periódicos de Depuração';

  @override
  String get settingEnableLineClipping => 'Recortar Linhas Cruzadas';

  @override
  String get settingPolyColor => 'Cor do Politopo';

  @override
  String get settingPolyEdgeThickness => 'Espessura das Arestas do Politopo';

  @override
  String get settingShowHotkeyButtons => 'Mostrar Botões de Atalho';

  @override
  String get settingSliceColor => 'Cor do Corte';

  @override
  String get settingSliceEdgeThickness => 'Espessura das Arestas do Corte';

  @override
  String get settingStickyDelay => 'Atraso de Fixação';

  @override
  String get settingStickyRadius => 'Raio de Fixação';

  @override
  String get settingThemeBrightness => 'Brilho do Tema';

  @override
  String get settingThemeColor => 'Cor do Tema';

  @override
  String get settingVertexRadius => 'Tamanho dos Vértices';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsTooltip => 'Configurações';

  @override
  String get showSliceTooltip => 'Mostrar corte';

  @override
  String get sliceLabel => 'corte:';

  @override
  String get slicesTab => 'Cortes';

  @override
  String get sliderSlice => 'Corte';

  @override
  String get snapCell => '3-célula na frente';

  @override
  String get snapCellTip =>
      'Girar o politopo para que uma 3-célula fique na frente';

  @override
  String get snapEdge => 'Aresta na frente';

  @override
  String get snapEdgeTip =>
      'Girar o politopo para que uma aresta fique na frente';

  @override
  String get snapFace => 'Face na frente';

  @override
  String get snapFaceTip =>
      'Girar o politopo para que uma face fique na frente';

  @override
  String get snapVertex => 'Vértice na frente';

  @override
  String get snapVertexTip =>
      'Girar o politopo para que um vértice fique na frente';

  @override
  String get switchLanguageTooltip => 'Alterar idioma';

  @override
  String get switchToArTooltip => 'Alternar para modo RA';

  @override
  String get termsTab => 'Termos';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeSystem => 'Sistema';
}
