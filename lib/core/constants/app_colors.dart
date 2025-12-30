import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  const AppColors._();

  static const Color gradientStart = Color(0xFF6A11CB);
  static const Color gradientEnd = Color(0xFF2575FC);

  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(
    0xFF757575,
  ); // aproximation of grey[600]

  static const Color inputFill = Color(0xFFFAFAFA); // approximation of grey[50]
  static const Color white = Colors.white;

  static const Color snackBarSuccess = Colors.green;
  static const Color snackBarError = Colors.redAccent;

  static const Color buttonBackground = Color(0xFF6A11CB);
  static const Color buttonForeground = Colors.white;
  static const Color primary = Color(0xFF6A11CB);
}
