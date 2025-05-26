import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class Helpers {
  static void showSnackBar(BuildContext context, String message, {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? AppColors.error : AppColors.success, duration: duration));
  }

  static Future<bool> showConfirmDialog(BuildContext context, String title, String message, {String confirmText = 'Confirm', String cancelText = 'Cancel'}) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor), child: Text(confirmText))],
          ),
    );

    return result ?? false;
  }

  static String formatCurrency(double amount) {
    return 'R${amount.toStringAsFixed(2)}';
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    return password.length >= 8 && password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[0-9]'));
  }
}
