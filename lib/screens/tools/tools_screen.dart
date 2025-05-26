import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/tool.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/helper.dart';
import '../../widgets/custom_button.dart';
import '../payments/payment_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  ToolCategory _selectedCategory = ToolCategory.financial;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isPremium = authProvider.currentUser?.isPremium ?? false;

    // Filtered tools based on selected category
    final filteredTools = predefinedTools.where((tool) => _selectedCategory == ToolCategory.general || tool.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Business Tools', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            // Category tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryButton(context, 'All Tools', Icons.build, ToolCategory.general),
                    _buildCategoryButton(context, 'Financial', Icons.attach_money, ToolCategory.financial),
                    _buildCategoryButton(context, 'Marketing', Icons.campaign, ToolCategory.marketing),
                    _buildCategoryButton(context, 'Legal', Icons.gavel, ToolCategory.legal),
                  ],
                ),
              ),
            ),

            // Tools grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 16, mainAxisSpacing: 16),
                  itemCount: filteredTools.length,
                  itemBuilder: (context, index) {
                    final tool = filteredTools[index];
                    return _buildToolCard(context, tool, authProvider);
                  },
                ),
              ),
            ),

            // Premium features banner
            if (!isPremium)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(gradient: AppStyles.primaryGradient, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unlock Pro Features', style: AppStyles.h3(isDarkMode: true).copyWith(color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Get advanced tools, team collaboration, and AI advisor features', style: AppStyles.bodyMedium(isDarkMode: true).copyWith(color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Upgrade to Pro',
                        icon: Icons.star,
                        onPressed: () {
                          _processUpgrade(context);
                        },
                        type: ButtonType.secondary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, String title, IconData icon, ToolCategory category) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isActive = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0, bottom: 16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AppColors.primaryColor : (isDarkMode ? AppColors.darkCard : Colors.grey[200]),
          foregroundColor: isActive ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, Tool tool, AuthProvider authProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasAccess = !tool.isPremium || authProvider.hasAccessToTool(tool.id);

    return InkWell(
      onTap: () {
        if (hasAccess) {
          _openTool(context, tool.id);
        } else {
          _showToolPurchaseDialog(context, tool);
        }
      },
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

  void _openTool(BuildContext context, String toolId) {
    // Navigate to the specific tool screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          switch (toolId) {
            // Financial tools
            case 'invoice_generator':
              return InvoiceGeneratorScreen();
            case 'budget_builder':
              return BudgetBuilderScreen();
            case 'profit_forecast':
              return ProfitForecastScreen();
            case 'tax_calculator':
              return TaxCalculatorScreen();

            // Marketing tools
            case 'marketing_plan':
              return MarketingPlanScreen();
            case 'audience_finder':
              return AudienceFinderScreen();
            case 'content_writer':
              return ContentWriterScreen();
            case 'social_planner':
              return SocialPlannerScreen();

            // Legal tools
            case 'contract_maker':
              return ContractMakerScreen();
            case 'ip_checker':
              return IPCheckerScreen();
            case 'privacy_policy':
              return PrivacyPolicyScreen();
            case 'legal_advisor':
              return LegalAdvisorScreen();

            // General tools
            case 'business_plan':
              return BusinessPlanScreen();
            case 'pitch_deck':
              return PitchDeckScreen();

            default:
              return UnknownToolScreen();
          }
        },
      ),
    );
  }

  void _showToolPurchaseDialog(BuildContext context, Tool tool) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Purchase ${tool.name}'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('This tool costs R${tool.price.toStringAsFixed(0)}.'), const SizedBox(height: 8), Text('Would you like to purchase it for one-time use?')]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processPurchase(context, tool);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                child: const Text('Purchase'),
              ),
            ],
          ),
    );
  }

  void _processPurchase(BuildContext context, Tool tool) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => PaymentScreen(
              amount: tool.price,
              toolId: tool.id,
              toolName: tool.name,
              onSuccess: () async {
                final success = await authProvider.purchaseTool(tool.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully purchased ${tool.name}!'), backgroundColor: AppColors.success));
                  _openTool(context, tool.id);
                }
              },
            ),
      ),
    );
  }

  Future<void> _processUpgrade(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading indicator
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      // Process the upgrade
      final success = await authProvider.upgradeSubscription();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          Helpers.showSnackBar(context, 'Successfully upgraded to Premium!');
        } else {
          Helpers.showSnackBar(context, 'Failed to process upgrade. Please try again.', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }
}

// Placeholder classes for tool screens
class InvoiceGeneratorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Invoice Generator')));
}

class BudgetBuilderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Budget Builder')));
}

class ProfitForecastScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Profit Forecast')));
}

class TaxCalculatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Tax Calculator')));
}

class MarketingPlanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Marketing Plan')));
}

class AudienceFinderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Audience Finder')));
}

class ContentWriterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Content Writer')));
}

class SocialPlannerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Social Planner')));
}

class ContractMakerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Contract Maker')));
}

class IPCheckerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('IP Checker')));
}

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Privacy Policy')));
}

class LegalAdvisorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Legal Advisor')));
}

class BusinessPlanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Business Plan')));
}

class PitchDeckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Pitch Deck')));
}

class UnknownToolScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Tool Not Found')));
}
