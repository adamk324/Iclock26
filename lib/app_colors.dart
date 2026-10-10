import 'package:flutter/cupertino.dart';

class AppColors {
  const AppColors._(this.isDark);

  final bool isDark;

  static const List<Color> accentPalette = <Color>[
    CupertinoColors.systemOrange,
    CupertinoColors.systemBlue,
    CupertinoColors.systemGreen,
    CupertinoColors.systemPink,
    CupertinoColors.systemPurple,
    CupertinoColors.systemRed,
    CupertinoColors.systemYellow,
    CupertinoColors.systemTeal,
  ];

  static AppColors of(BuildContext context) {
    return AppColors._(
      CupertinoTheme.brightnessOf(context) == Brightness.dark,
    );
  }

  Color get background =>
      isDark ? CupertinoColors.black : const Color(0xFFF2F2F7);
  Color get primaryText =>
      isDark ? CupertinoColors.white : CupertinoColors.black;
  Color get secondaryText =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D72);
  Color get separator =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);
  Color get secondaryButton =>
      isDark ? const Color(0xFF333336) : const Color(0xFFE5E5EA);
  Color get success => CupertinoColors.systemGreen;
  Color get danger => CupertinoColors.systemRed;
  Color get successButtonFill =>
      isDark ? const Color(0xFF173A20) : const Color(0xFFDDF5E2);
  Color get dangerButtonFill =>
      isDark ? const Color(0xFF3A1717) : const Color(0xFFF8DEDE);
  Color get glassFillBase =>
      isDark ? const Color(0xFF262628) : CupertinoColors.white;
  Color get glassBorderBase =>
      isDark ? const Color(0x33FFFFFF) : const Color(0x33000000);
  Color get glassSelection =>
      isDark ? const Color(0x2EFFFFFF) : const Color(0x66FFFFFF);
}
