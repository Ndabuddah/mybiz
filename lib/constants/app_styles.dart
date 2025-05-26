import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppStyles {
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(colors: AppColors.primaryGradient, begin: Alignment.topLeft, end: Alignment.bottomRight);

  // Typography
  static TextStyle h1({bool isDarkMode = false}) {
    return TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDarkMode ? AppColors.darkText : AppColors.lightText);
  }

  static TextStyle h2({bool isDarkMode = false}) {
    return TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDarkMode ? AppColors.darkText : AppColors.lightText);
  }

  static TextStyle h3({bool isDarkMode = false}) {
    return TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? AppColors.darkText : AppColors.lightText);
  }

  static TextStyle bodyLarge({bool isDarkMode = false}) {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDarkMode ? AppColors.darkText : AppColors.lightText);
  }

  static TextStyle bodyMedium({bool isDarkMode = false}) {
    return TextStyle(fontSize: 14, color: isDarkMode ? AppColors.darkText.withOpacity(0.9) : AppColors.lightText.withOpacity(0.9));
  }

  static TextStyle bodySmall({bool isDarkMode = false}) {
    return TextStyle(fontSize: 12, color: isDarkMode ? AppColors.darkText.withOpacity(0.8) : AppColors.lightText.withOpacity(0.8));
  }

  // Box decorations
  static BoxDecoration cardDecoration({bool isDarkMode = false}) {
    return BoxDecoration(color: isDarkMode ? AppColors.darkCard : AppColors.lightCard, borderRadius: BorderRadius.circular(16), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]);
  }

  static BoxDecoration gradientDecoration() {
    return BoxDecoration(gradient: primaryGradient, borderRadius: BorderRadius.circular(16));
  }
}
