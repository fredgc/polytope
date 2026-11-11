// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get aboutTab => '关于';

  @override
  String get appTitle => '多胞体演示';

  @override
  String get cancelButton => '取消';

  @override
  String get closeTooltip => '关闭';

  @override
  String get colorPickerTitle => '选取颜色';

  @override
  String get controlsTab => '控制';

  @override
  String get debugTooltip => '调试';

  @override
  String get decreaseSpeedTooltip => '降低速度';

  @override
  String dimButtonLabel(int dim) {
    return '$dim维';
  }

  @override
  String dimensionMenuLabel(int dim) {
    return '$dim维空间';
  }

  @override
  String get doneButton => '完成';

  @override
  String get doneTooltip => '保存并关闭';

  @override
  String get helpTitle => '帮助';

  @override
  String get helpTooltip => '帮助';

  @override
  String get increaseSpeedTooltip => '提高速度';

  @override
  String get initializingApp => '正在初始化应用...';

  @override
  String get initializingSettings => '正在初始化设置...';

  @override
  String get languageAuto => '自动';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get loadingText => '加载中...';

  @override
  String get movementRotate3 => 'R3 旋转';

  @override
  String get movementRotate3Tip => '拖拽鼠标将在 R3 空间中旋转多胞体';

  @override
  String get movementRotate4 => 'R4 旋转';

  @override
  String get movementRotate4Tip => '拖拽鼠标将在 R4 空间中旋转多胞体';

  @override
  String get movementRotate5 => 'R5 旋转';

  @override
  String get movementRotate5Tip => '拖拽鼠标将在 R5 空间中旋转多胞体';

  @override
  String get movementScale => '缩放';

  @override
  String get movementScaleTip => '拖拽鼠标放大或缩小多胞体';

  @override
  String get movementTranslate => '平移';

  @override
  String get movementTranslateTip => '拖拽鼠标平移多胞体';

  @override
  String get movementZolly => '滑动变焦';

  @override
  String get movementZollyTip => '变焦 + 移动。拖拽鼠标改变透视视角。';

  @override
  String get overviewTab => '概述';

  @override
  String get polytopeCell120 => '正120胞体';

  @override
  String get polytopeCell24 => '正24胞体';

  @override
  String get polytopeCell600 => '正600胞体';

  @override
  String get polytopeCross => '正轴体';

  @override
  String get polytopeCube => '超立方体';

  @override
  String get polytopeDodec => '正十二面体';

  @override
  String get polytopeIco => '正二十面体';

  @override
  String get polytopeSimplex => '单纯形';

  @override
  String get privacyTab => '隐私';

  @override
  String settingAppVersion(String appName, String version, String buildNumber) {
    return '应用程序 $appName 版本 $version.$buildNumber';
  }

  @override
  String get settingBackgroundColor => '背景颜色';

  @override
  String get settingClipGapSize => '裁剪间隔大小';

  @override
  String get settingDebugLogs => '定期调试日志';

  @override
  String get settingEnableLineClipping => '裁剪相交线';

  @override
  String get settingPolyColor => '多胞体颜色';

  @override
  String get settingPolyEdgeThickness => '多胞体边缘粗细';

  @override
  String get settingShowHotkeyButtons => '显示快捷键按钮';

  @override
  String get settingSliceColor => '截面颜色';

  @override
  String get settingSliceEdgeThickness => '截面边缘粗细';

  @override
  String get settingStickyDelay => '吸附延迟';

  @override
  String get settingStickyRadius => '吸附半径';

  @override
  String get settingThemeBrightness => '主题亮度';

  @override
  String get settingThemeColor => '主题颜色';

  @override
  String get settingVertexRadius => '顶点大小';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsTooltip => '设置';

  @override
  String get showSliceTooltip => '显示截面';

  @override
  String get sliceLabel => '截面:';

  @override
  String get slicesTab => '截面';

  @override
  String get sliderSlice => '截面';

  @override
  String get snapCell => '三维胞朝前';

  @override
  String get snapCellTip => '旋转多胞体使三维胞朝前';

  @override
  String get snapEdge => '棱朝前';

  @override
  String get snapEdgeTip => '旋转多胞体使棱朝前';

  @override
  String get snapFace => '面朝前';

  @override
  String get snapFaceTip => '旋转多胞体使面朝前';

  @override
  String get snapVertex => '顶点朝前';

  @override
  String get snapVertexTip => '旋转多胞体使顶点朝前';

  @override
  String get switchLanguageTooltip => '切换语言';

  @override
  String get switchToArTooltip => '切换到 AR 模式';

  @override
  String get termsTab => '条款';

  @override
  String get themeModeDark => '深色';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeSystem => '系统';
}
