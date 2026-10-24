import 'package:flutter/material.dart';

/// Brand colours taken from the UniMarkLy icon: deep navy, lime green and a
/// clear blue. Dark and light themes share them.
class Brand {
  const Brand._();

  static const navy = Color(0xFF0B2A63);
  static const lime = Color(0xFFA6F23B);
  static const limeDeep = Color(0xFF2E8B1B);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const amber = Color(0xFFF5A524);

  /// The lime of the primary buttons, left to right.
  static const limeGradient = [Color(0xFFB9F53C), Color(0xFF6BE43A)];
}

/// Colours the Material scheme has no slot for: status colours and the tinted
/// tiles used on the course dashboard.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.successContainer,
    required this.warningContainer,
    required this.dangerContainer,
    required this.infoContainer,
    required this.tileGreen,
    required this.tileBlue,
    required this.tilePurple,
    required this.tileAmber,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color successContainer;
  final Color warningContainer;
  final Color dangerContainer;
  final Color infoContainer;
  final Color tileGreen;
  final Color tileBlue;
  final Color tilePurple;
  final Color tileAmber;

  static const dark = AppColors(
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFFF7A7A),
    info: Color(0xFF60A5FA),
    successContainer: Color(0xFF123524),
    warningContainer: Color(0xFF3A2B0B),
    dangerContainer: Color(0xFF3F1620),
    infoContainer: Color(0xFF14284F),
    tileGreen: Color(0xFF3FB950),
    tileBlue: Color(0xFF4C8DFF),
    tilePurple: Color(0xFFA78BFA),
    tileAmber: Color(0xFFF5B031),
  );

  static const light = AppColors(
    success: Color(0xFF1B7F3B),
    warning: Color(0xFF8A5A00),
    danger: Color(0xFFB3261E),
    info: Color(0xFF1D4ED8),
    successContainer: Color(0xFFDDF5E3),
    warningContainer: Color(0xFFFFEFC7),
    dangerContainer: Color(0xFFFCE0DD),
    infoContainer: Color(0xFFDCE8FF),
    tileGreen: Color(0xFF1F9D3A),
    tileBlue: Color(0xFF2563EB),
    tilePurple: Color(0xFF7C3AED),
    tileAmber: Color(0xFFC77700),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 ? this : (other as AppColors? ?? this);
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

// ignore: avoid_classes_with_only_static_members
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: Brand.lime,
          onPrimary: Color(0xFF0A1A05),
          primaryContainer: Color(0xFF1F3A12),
          onPrimaryContainer: Color(0xFFD9FFA8),
          secondary: Brand.blue,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFF14284F),
          onSecondaryContainer: Color(0xFFD6E4FF),
          tertiary: Brand.purple,
          onTertiary: Colors.white,
          error: Color(0xFFFF7A7A),
          onError: Color(0xFF2B0A0A),
          errorContainer: Color(0xFF3F1620),
          onErrorContainer: Color(0xFFFFD9D9),
          surface: Color(0xFF0D1631),
          onSurface: Color(0xFFEAF0FF),
          onSurfaceVariant: Color(0xFFA9B6D6),
          surfaceContainerLowest: Color(0xFF060C1E),
          surfaceContainerLow: Color(0xFF0B1330),
          surfaceContainer: Color(0xFF111B3B),
          surfaceContainerHigh: Color(0xFF16224A),
          surfaceContainerHighest: Color(0xFF1C2A58),
          outline: Color(0xFF52638F),
          outlineVariant: Color(0xFF28365F),
        ),
        scaffold: const Color(0xFF070D1F),
        colors: AppColors.dark,
      );

  static ThemeData get light => _build(
        const ColorScheme(
          brightness: Brightness.light,
          primary: Brand.limeDeep,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD8F7AE),
          onPrimaryContainer: Color(0xFF123300),
          secondary: Color(0xFF2563EB),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFDCE8FF),
          onSecondaryContainer: Color(0xFF0B2A63),
          tertiary: Color(0xFF7C3AED),
          onTertiary: Colors.white,
          error: Color(0xFFB3261E),
          onError: Colors.white,
          errorContainer: Color(0xFFFCE0DD),
          onErrorContainer: Color(0xFF410002),
          surface: Colors.white,
          onSurface: Color(0xFF0F1B3D),
          onSurfaceVariant: Color(0xFF4A587C),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xFFF7F9FE),
          surfaceContainer: Color(0xFFEFF3FB),
          surfaceContainerHigh: Color(0xFFE6ECF8),
          surfaceContainerHighest: Color(0xFFDCE4F4),
          outline: Color(0xFF7A88AD),
          outlineVariant: Color(0xFFCCD5EA),
        ),
        scaffold: const Color(0xFFF3F6FC),
        colors: AppColors.light,
      );

  static ThemeData _build(
    ColorScheme scheme, {
    required Color scaffold,
    required AppColors colors,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      extensions: [colors],
    );

    // Larger than the Material defaults: readable at arm's length, and still
    // scales with the phone's text-size setting.
    final text = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 17),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.35),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15.5, height: 1.35),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    );

    final radius = BorderRadius.circular(16);
    return base.copyWith(
      textTheme: text,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: scheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge?.copyWith(fontSize: 14),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
    );
  }
}
