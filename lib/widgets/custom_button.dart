import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool fullWidth;
  final double? height;

  const CustomButton({Key? key, required this.text, this.icon, required this.onPressed, this.type = ButtonType.primary, this.isLoading = false, this.fullWidth = false, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 8), child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(isDarkMode)))) else if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(text),
      ],
    );

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size(fullWidth ? double.infinity : 0, height ?? 48),
          ),
          child: buttonChild,
        );

      case ButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size(fullWidth ? double.infinity : 0, height ?? 48),
          ),
          child: buttonChild,
        );

      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDarkMode ? Colors.white : AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: BorderSide(color: isDarkMode ? Colors.white54 : AppColors.primaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size(fullWidth ? double.infinity : 0, height ?? 48),
          ),
          child: buttonChild,
        );

      case ButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(foregroundColor: isDarkMode ? Colors.white : AppColors.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: Size(fullWidth ? double.infinity : 0, height ?? 48)),
          child: buttonChild,
        );
    }
  }

  Color _getTextColor(bool isDarkMode) {
    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return AppColors.primaryColor;
      case ButtonType.outline:
      case ButtonType.text:
        return isDarkMode ? Colors.white : AppColors.primaryColor;
    }
  }
}
