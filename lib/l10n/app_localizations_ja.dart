// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get aboutTab => '情報';

  @override
  String get appTitle => '多胞体デモ';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get closeTooltip => '閉じる';

  @override
  String get colorPickerTitle => '色を選択';

  @override
  String get controlsTab => '操作方法';

  @override
  String get debugTooltip => 'デバッグ';

  @override
  String get decreaseSpeedTooltip => '速度を下げる';

  @override
  String dimButtonLabel(int dim) {
    return '$dim次元';
  }

  @override
  String dimensionMenuLabel(int dim) {
    return '$dim次元';
  }

  @override
  String get doneButton => '完了';

  @override
  String get doneTooltip => '保存して閉じる';

  @override
  String get helpTitle => 'ヘルプ';

  @override
  String get helpTooltip => 'ヘルプ';

  @override
  String get increaseSpeedTooltip => '速度を上げる';

  @override
  String get initializingApp => 'アプリを初期化中...';

  @override
  String get initializingSettings => '設定を初期化中...';

  @override
  String get languageAuto => '自動';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get loadingText => '読み込み中...';

  @override
  String get movementRotate3 => 'R3回転';

  @override
  String get movementRotate3Tip => 'ドラッグして多胞体をR3で回転します';

  @override
  String get movementRotate4 => 'R4回転';

  @override
  String get movementRotate4Tip => 'ドラッグして多胞体をR4で回転します';

  @override
  String get movementRotate5 => 'R5回転';

  @override
  String get movementRotate5Tip => 'ドラッグして多胞体をR5で回転します';

  @override
  String get movementScale => '拡大縮小';

  @override
  String get movementScaleTip => 'ドラッグして多胞体を拡大または縮小します';

  @override
  String get movementTranslate => '平行移動';

  @override
  String get movementTranslateTip => 'ドラッグして多胞体を移動します';

  @override
  String get movementZolly => 'ゾリー';

  @override
  String get movementZollyTip => 'ゾリー = ズーム + ドリー。ドラッグしてパースペクティブを変更します。';

  @override
  String get overviewTab => '概要';

  @override
  String get polytopeCell120 => '正120胞体';

  @override
  String get polytopeCell24 => '正24胞体';

  @override
  String get polytopeCell600 => '正600胞体';

  @override
  String get polytopeCross => '正軸体';

  @override
  String get polytopeCube => '超立方体';

  @override
  String get polytopeDodec => '正十二面体';

  @override
  String get polytopeIco => '正二十面体';

  @override
  String get polytopeSimplex => '単体';

  @override
  String get privacyTab => 'プライバシー';

  @override
  String settingAppVersion(String appName, String version, String buildNumber) {
    return 'アプリケーション $appName バージョン $version.$buildNumber';
  }

  @override
  String get settingBackgroundColor => '背景色';

  @override
  String get settingClipGapSize => 'クリッピング間隔サイズ';

  @override
  String get settingDebugLogs => '定期デバッグログ';

  @override
  String get settingEnableLineClipping => '交差線をクリッピング';

  @override
  String get settingPolyColor => '多胞体の色';

  @override
  String get settingPolyEdgeThickness => '多胞体のエッジの太さ';

  @override
  String get settingShowHotkeyButtons => 'ホットキーボタンを表示';

  @override
  String get settingSliceColor => '切断面の色';

  @override
  String get settingSliceEdgeThickness => '切断面のエッジの太さ';

  @override
  String get settingStickyDelay => '吸着遅延';

  @override
  String get settingStickyRadius => '吸着半径';

  @override
  String get settingThemeBrightness => 'テーマの明るさ';

  @override
  String get settingThemeColor => 'テーマカラー';

  @override
  String get settingVertexRadius => '頂点サイズ';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsTooltip => '設定';

  @override
  String get showSliceTooltip => '断面を表示';

  @override
  String get sliceLabel => '断面:';

  @override
  String get slicesTab => '断面';

  @override
  String get sliderSlice => '断面';

  @override
  String get snapCell => '3-胞を前面に';

  @override
  String get snapCellTip => '3-胞が前面になるように多胞体を回転';

  @override
  String get snapEdge => '辺を前面に';

  @override
  String get snapEdgeTip => '辺が前面になるように多胞体を回転';

  @override
  String get snapFace => '面を前面に';

  @override
  String get snapFaceTip => '面が前面になるように多胞体を回転';

  @override
  String get snapVertex => '頂点を前面に';

  @override
  String get snapVertexTip => '頂点が前面になるように多胞体を回転';

  @override
  String get switchLanguageTooltip => '言語を切り替える';

  @override
  String get switchToArTooltip => 'ARモードに切り替え';

  @override
  String get termsTab => '利用規約';

  @override
  String get themeModeDark => 'ダーク';

  @override
  String get themeModeLight => 'ライト';

  @override
  String get themeModeSystem => 'システム';
}
