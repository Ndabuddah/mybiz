import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/tool.dart';

class ToolCard extends StatelessWidget {
  final Tool tool;
  final bool hasAccess;
  final VoidCallback onTap;

  const ToolCard({Key? key, required this.tool, required this.hasAccess, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: tool.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(tool.icon, color: tool.color, size: 24)),
            const SizedBox(height: 16),
            Text(tool.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(tool.description, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            if (tool.isPremium && !hasAccess) ...[
              Row(children: [const Icon(Icons.lock, size: 16, color: AppColors.primaryColor), const SizedBox(width: 4), Text('R${tool.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryColor))]),
            ] else ...[
              Row(children: [Icon(Icons.check_circle, size: 16, color: AppColors.success), const SizedBox(width: 4), Text(tool.isPremium ? 'Purchased' : 'Free', style: TextStyle(fontSize: 14, color: AppColors.success))]),
            ],
          ],
        ),
      ),
    );
  }
}
