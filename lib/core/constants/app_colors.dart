import 'package:flutter/material.dart';

/// Colores principales de la aplicación MiChaucherita
/// Paleta basada en tonos naranjas cálidos
class AppColors {
  AppColors._();

  // Primary Colors - Naranja
  static const Color primary = Color(0xFFFF6D00);
  static const Color primaryLight = Color(0xFFFF9E40);
  static const Color primaryDark = Color(0xFFE65100);
  static const Color primarySoft = Color(0xFFFFF3E0);

  // Secondary Colors
  static const Color secondary = Color(0xFF00BFA5);
  static const Color secondaryLight = Color(0xFF5DF2D6);
  static const Color secondaryDark = Color(0xFF008E76);

  // Semantic Colors
  static const Color income = Color(0xFF4CAF50);
  static const Color incomeLight = Color(0xFFE8F5E9);
  static const Color expense = Color(0xFFEF5350);
  static const Color expenseLight = Color(0xFFFFEBEE);
  static const Color transfer = Color(0xFF42A5F5);
  static const Color transferLight = Color(0xFFE3F2FD);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Shadows
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF5350), Color(0xFFE53935)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A50), Color(0xFFFF6D00)],
  );

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
}
