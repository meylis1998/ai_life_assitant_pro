import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Color palette for the daily briefing feature
/// Wraps AppTheme colors for compatibility
class ColorPalette {
  ColorPalette._();
  
  static const Color primary = AppTheme.primaryColor;
  static const Color secondary = AppTheme.secondaryColor;
  static const Color accent = AppTheme.accentColor;
  static const Color error = AppTheme.errorColor;
  static const Color success = AppTheme.successColor;
  static const Color warning = AppTheme.warningColor;
  
  // Additional colors for briefing UI
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
}
