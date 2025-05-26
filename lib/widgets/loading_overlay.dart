import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({Key? key, required this.child, required this.isLoading, this.message, this.backgroundColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (backgroundColor ?? (isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7))).withOpacity(0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 80, height: 80, child: Lottie.asset('assets/lottie/loading.json', fit: BoxFit.cover)),
                    if (message != null) ...[const SizedBox(height: 16), Text(message!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87), textAlign: TextAlign.center)],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
