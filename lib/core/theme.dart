import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Uygulamanın görsel dili: Manrope yazı tipi, yumuşak köşeler, M3 renkleri.
class AppTheme {
  AppTheme._();

  static const fontFamily = 'Manrope';
  static const radiusCard = 22.0;
  static const radiusField = 14.0;

  static ThemeData build(Color seed, Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    final isDark = b == Brightness.dark;
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: b,
      fontFamily: fontFamily,
    );
    final text = base.textTheme.apply(fontFamily: fontFamily).copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6),
          titleLarge: base.textTheme.titleLarge?.copyWith(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4),
          titleMedium: base.textTheme.titleMedium?.copyWith(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2),
          titleSmall: base.textTheme.titleSmall
              ?.copyWith(fontFamily: fontFamily, fontWeight: FontWeight.w700),
          labelLarge: base.textTheme.labelLarge
              ?.copyWith(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor:
          isDark ? scheme.surface : scheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard)),
        color: scheme.surfaceContainerLow,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        labelStyle: text.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusField),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusField),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusField),
            borderSide: BorderSide(color: scheme.primary, width: 1.6)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusField)),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusField)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusField)),
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle: text.labelLarge?.copyWith(fontSize: 15),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        textStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle:
            text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelStyle: text.labelLarge,
        unselectedLabelStyle:
            text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusField)),
          textStyle: text.labelLarge,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      dividerTheme: DividerThemeData(
          color: scheme.outlineVariant.withValues(alpha: 0.5), space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}

/// Renk yardımcıları
extension ColorX on Color {
  Color darken([double amount = .12]) {
    final h = HSLColor.fromColor(this);
    return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Color lighten([double amount = .12]) {
    final h = HSLColor.fromColor(this);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color shiftHue(double deg) {
    final h = HSLColor.fromColor(this);
    return h.withHue((h.hue + deg) % 360).toColor();
  }

  /// Şablon rengine uygun iki tonlu gradyan
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lighten(.06).shiftHue(-8), darken(.10).shiftHue(10)],
      );
}
