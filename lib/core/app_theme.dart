import 'package:flutter/material.dart';

/// Design system terpusat untuk seluruh aplikasi Gudang RBAC.
/// Semua halaman wajib memakai token dari sini — dilarang hardcode
/// warna/radius di file lain agar tampilan konsisten & mudah diubah.
abstract final class AppColors {
  static const primaryTeal = Color(0xFF145858);
  static const tealDeep = Color(0xFF0E3F40);
  static const softMint = Color(0xFFC8E0CA);
  static const paleMint = Color(0xFFEEF5EF);
  static const surface = Colors.white;
  static const warmAmber = Color(0xFFF7B318);
  static const amberSoft = Color(0xFFFFF4D6);
  static const darkText = Color(0xFF102A2A);
  static const textMuted = Color(0xFF5B6B68);
  static const border = Color(0xFFDCE9DD);
  static const successBg = Color(0xFFE3F2E7);
  static const errorRed = Color(0xFFB3261E);
  static const errorBg = Color(0xFFFCE8E6);
}

abstract final class AppRadius {
  static const card = 18.0;
  static const button = 14.0;
  static const field = 14.0;
  static const chip = 12.0;
  static const tile = 14.0;
}

/// Kartu putih standar dengan border mint & shadow lembut.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12102A2A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Banner status inline (dipakai menggantikan kombinasi banner+snackbar ganda).
class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.message,
    required this.isError,
    this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isError ? AppColors.errorBg : AppColors.successBg,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: isError ? AppColors.errorRed : AppColors.primaryTeal,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.errorRed : AppColors.primaryTeal,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (onDismiss != null)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onDismiss,
                child: const Icon(Icons.close,
                    color: AppColors.textMuted, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primaryTeal,
    primary: AppColors.primaryTeal,
    secondaryContainer: AppColors.softMint,
    tertiary: AppColors.warmAmber,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.paleMint,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.6),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkText,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    ),
  );
}
