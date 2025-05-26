import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/helper.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final user = authProvider.currentUser;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: AppStyles.primaryGradient, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, image: user?.photoUrl != null ? DecorationImage(image: NetworkImage(user!.photoUrl!), fit: BoxFit.cover) : null),
                      child: user?.photoUrl == null ? Center(child: Text(user?.name?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))) : null,
                    ),
                    const SizedBox(width: 24),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(user?.email ?? 'email@example.com', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: Text(isPremium ? 'Premium' : 'Free Plan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Subscription section
              if (isPremium) ...[
                Text('Subscription', style: AppStyles.h3(isDarkMode: isDarkMode)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      _buildInfoRow('Plan', 'Premium', Icons.star, AppColors.primaryColor, isDarkMode),
                      const Divider(),
                      _buildInfoRow('Status', 'Active', Icons.check_circle, Colors.green, isDarkMode),
                      const Divider(),
                      _buildInfoRow('Expires', subscriptionProvider.premiumEndDate != null ? subscriptionProvider.formatDate(subscriptionProvider.premiumEndDate!) : 'Never', Icons.calendar_today, Colors.blue, isDarkMode),
                      const Divider(),
                      _buildInfoRow('Days Remaining', subscriptionProvider.getRemainingDays(), Icons.timer, Colors.orange, isDarkMode),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final confirmed = await Helpers.showConfirmDialog(context, 'Cancel Subscription', 'Are you sure you want to cancel your premium subscription? You will lose access to premium features.', confirmText: 'Cancel Subscription', cancelText: 'Keep Subscription');

                    if (confirmed) {
                      await subscriptionProvider.cancelPremium();
                    }
                  },
                  child: Text('Cancel Subscription', style: TextStyle(color: Colors.red)),
                ),
              ] else ...[
                Text('Upgrade to Premium', style: AppStyles.h3(isDarkMode: isDarkMode)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      Text('Unlock all premium features', style: AppStyles.bodyLarge(isDarkMode: isDarkMode)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildPricingOption(context, 'Monthly', 'R99.99', '/month', 1, isDarkMode),
                          const SizedBox(width: 12),
                          _buildPricingOption(context, '6 Months', 'R499.99', '/6 months', 6, isDarkMode, isBestValue: true),
                          const SizedBox(width: 12),
                          _buildPricingOption(context, 'Annual', 'R899.99', '/year', 12, isDarkMode),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Settings section
              Text('Settings', style: AppStyles.h3(isDarkMode: isDarkMode)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  children: [
                    _buildSettingItem(
                      'Dark Mode',
                      Icons.dark_mode,
                      isDarkMode,
                      trailing: Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      'Notifications',
                      Icons.notifications,
                      isDarkMode,
                      onTap: () {
                        // Navigate to notifications settings
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      'Privacy',
                      Icons.privacy_tip,
                      isDarkMode,
                      onTap: () {
                        // Navigate to privacy settings
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      'Help & Support',
                      Icons.help,
                      isDarkMode,
                      onTap: () {
                        // Navigate to help & support
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      'About',
                      Icons.info,
                      isDarkMode,
                      onTap: () {
                        // Navigate to about
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Logout',
                  icon: Icons.logout,
                  onPressed: () async {
                    final confirmed = await Helpers.showConfirmDialog(context, 'Logout', 'Are you sure you want to logout?', confirmText: 'Logout', cancelText: 'Cancel');

                    if (confirmed) {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                      }
                    }
                  },
                  type: ButtonType.outline,
                ),
              ),

              const SizedBox(height: 16),

              // App version
              Center(child: Text('MyBiz v1.0.0', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45))),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 16)),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPricingOption(BuildContext context, String title, String price, String period, int months, bool isDarkMode, {bool isBestValue = false}) {
    return Expanded(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: isBestValue ? Border.all(color: AppColors.primaryColor, width: 2) : null),
            child: Column(
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                Text(period, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
                      await subscriptionProvider.upgradeToPremium(monthsDuration: months);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBestValue
                              ? AppColors.primaryColor
                              : isDarkMode
                              ? Colors.white24
                              : Colors.black12,
                      foregroundColor:
                          isBestValue
                              ? Colors.white
                              : isDarkMode
                              ? Colors.white
                              : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    child: Text('Select'),
                  ),
                ),
              ],
            ),
          ),
          if (isBestValue)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomLeft: Radius.circular(12))),
                child: const Text('Best Value', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, bool isDarkMode, {VoidCallback? onTap, Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primaryColor, size: 18)),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.white54 : Colors.black45) : const SizedBox()),
          ],
        ),
      ),
    );
  }
}
