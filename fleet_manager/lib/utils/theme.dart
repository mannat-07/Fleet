import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Shared accent colors (same in both themes) ─────────────────────────────
class AppColors {
  static const Color orangeStart = Color(0xFFFF5A1F);
  static const Color orangeEnd = Color(0xFFFF2D00);
  static const Color green = Color(0xFF4CAF50);
  static const Color amber = Color(0xFFFFC107);
  static const Color red = Color(0xFFFF5252);
  static const Color blue = Color(0xFF4FC3F7);
  static const Color purple = Color(0xFFAB47BC);

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orangeStart, orangeEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// ─── Per-theme color tokens ──────────────────────────────────────────────────
class FleetColors {
  final Color background;
  final Color backgroundEnd;
  final Color surface;
  final Color surfaceHigh;
  final Color cardBorder;
  final Color cardBg;
  final Color text;
  final Color textSub;
  final Color iconBg;
  final Color inputBg;
  final Color inputBorder;
  final Color divider;
  final Color tooltipBg;
  final Color chartGrid;
  final Color backBtnBg;
  final Color backBtnBorder;
  final Color sheetBg;
  final bool isDark;

  const FleetColors({
    required this.background,
    required this.backgroundEnd,
    required this.surface,
    required this.surfaceHigh,
    required this.cardBorder,
    required this.cardBg,
    required this.text,
    required this.textSub,
    required this.iconBg,
    required this.inputBg,
    required this.inputBorder,
    required this.divider,
    required this.tooltipBg,
    required this.chartGrid,
    required this.backBtnBg,
    required this.backBtnBorder,
    required this.sheetBg,
    required this.isDark,
  });

  static const FleetColors dark = FleetColors(
    background: Color(0xFF0B0B0B),
    backgroundEnd: Color(0xFF121212),
    surface: Color(0xFF1A1A1A),
    surfaceHigh: Color(0xFF242424),
    cardBorder: Color(0x1AFFFFFF),
    cardBg: Color(0x12FFFFFF),
    text: Color(0xFFFFFFFF),
    textSub: Color(0xFF9E9E9E),
    iconBg: Color(0xFF2A2A2A),
    inputBg: Color(0x0DFFFFFF),
    inputBorder: Color(0x1AFFFFFF),
    divider: Color(0x14FFFFFF),
    tooltipBg: Color(0xFF2A2A2A),
    chartGrid: Color(0x0DFFFFFF),
    backBtnBg: Color(0x12FFFFFF),
    backBtnBorder: Color(0x1AFFFFFF),
    sheetBg: Color(0xFF1A1A1A),
    isDark: true,
  );

  static const FleetColors light = FleetColors(
    background: Color(0xFFF4F6FA),
    backgroundEnd: Color(0xFFEAEDF5),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF0F2F8),
    cardBorder: Color(0x1A000000),
    cardBg: Color(0xFFFFFFFF),
    text: Color(0xFF0F1117),
    textSub: Color(0xFF6B7280),
    iconBg: Color(0xFFF0F2F8),
    inputBg: Color(0xFFF7F8FC),
    inputBorder: Color(0xFFE2E6F0),
    divider: Color(0xFFE5E7EB),
    tooltipBg: Color(0xFFFFFFFF),
    chartGrid: Color(0x14000000),
    backBtnBg: Color(0xFFFFFFFF),
    backBtnBorder: Color(0xFFE2E6F0),
    sheetBg: Color(0xFFFFFFFF),
    isDark: false,
  );

  LinearGradient get backgroundGradient => LinearGradient(
    colors: [background, backgroundEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─── InheritedWidget theme provider ─────────────────────────────────────────
class FleetTheme extends InheritedWidget {
  final FleetColors colors;
  final VoidCallback toggle;

  const FleetTheme({
    super.key,
    required this.colors,
    required this.toggle,
    required super.child,
  });

  static FleetTheme of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<FleetTheme>();
    assert(result != null, 'No FleetTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(FleetTheme old) => old.colors != colors;
}

// ─── Material ThemeData ──────────────────────────────────────────────────────
class AppTheme {
  static ThemeData build(FleetColors c) {
    final base = c.isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.orangeStart,
        surface: c.surface,
      ),
    );
  }
}
