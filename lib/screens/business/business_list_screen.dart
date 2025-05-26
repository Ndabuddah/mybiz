import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/business.dart';
import '../../providers/business_provider.dart';
import '../../utils/helper.dart';
import '../../widgets/custom_button.dart';
import 'add_business_screen.dart';
import 'business_details_screen.dart';

class BusinessListScreen extends StatelessWidget {
  const BusinessListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Businesses', style: AppStyles.h2(isDarkMode: isDarkMode)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBusinessScreen()));
            },
            icon: const Icon(Icons.add_business),
            tooltip: 'Add Business',
          ),
        ],
      ),
      body: SafeArea(
        child:
            businessProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : businessProvider.businesses.isEmpty
                ? _buildEmptyState(context, isDarkMode)
                : _buildBusinessList(context, businessProvider, isDarkMode),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 80, color: isDarkMode ? Colors.white24 : Colors.black12),
            const SizedBox(height: 24),
            Text('No Businesses Yet', style: AppStyles.h2(isDarkMode: isDarkMode), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Add your first business to get started with all the tools and features.', style: AppStyles.bodyLarge(isDarkMode: isDarkMode).copyWith(color: isDarkMode ? Colors.white70 : Colors.black54), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Add Business',
              icon: Icons.add_business,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBusinessScreen()));
              },
              type: ButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessList(BuildContext context, BusinessProvider businessProvider, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: businessProvider.businesses.length,
      itemBuilder: (context, index) {
        final business = businessProvider.businesses[index];
        return _buildBusinessCard(context, business, isDarkMode);
      },
    );
  }

  Widget _buildBusinessCard(BuildContext context, Business business, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDarkMode ? 0 : 2,
      color: isDarkMode ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailsScreen(business: business)));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Business logo or placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: AppColors.primaryColor.withOpacity(0.1), shape: BoxShape.circle, image: business.logo != null ? DecorationImage(image: NetworkImage(business.logo!), fit: BoxFit.cover) : null),
                child: business.logo == null ? Center(child: Text(business.name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryColor))) : null,
              ),
              const SizedBox(width: 16),
              // Business details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(business.industry, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 8),
                    Text(Helpers.truncateText(business.description, 60), style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.black45), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Arrow icon
              Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.white54 : Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
