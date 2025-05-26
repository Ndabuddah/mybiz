import 'package:flutter/material.dart';

class ToolPrice {
  // Financial tools
  static const double invoiceGenerator = 0.0; // Free
  static const double budgetBuilder = 0.0; // Free
  static const double profitForecast = 35.0;
  static const double taxCalculator = 25.0;

  // Marketing tools
  static const double marketingPlan = 0.0; // Free
  static const double audienceFinder = 30.0;
  static const double contentWriter = 20.0;
  static const double socialPlanner = 40.0;

  // Legal tools
  static const double contractMaker = 0.0; // Free
  static const double ipChecker = 45.0;
  static const double privacyPolicy = 0.0; // Free
  static const double legalAdvisor = 50.0;

  // Document generation
  static const double businessPlan = 15.0;
  static const double pitchDeck = 10.0;
  static const double marketingStrategy = 12.0;
  static const double swotAnalysis = 5.0;
  static const double financialForecast = 12.0;
  static const double executiveSummary = 5.0;

  // Maps tool IDs to prices
  static Map<String, double> priceMap = {
    // Financial tools
    'invoice_generator': invoiceGenerator,
    'budget_builder': budgetBuilder,
    'profit_forecast': profitForecast,
    'tax_calculator': taxCalculator,

    // Marketing tools
    'marketing_plan': marketingPlan,
    'audience_finder': audienceFinder,
    'content_writer': contentWriter,
    'social_planner': socialPlanner,

    // Legal tools
    'contract_maker': contractMaker,
    'ip_checker': ipChecker,
    'privacy_policy': privacyPolicy,
    'legal_advisor': legalAdvisor,

    // Document generation
    'document_business_plan': businessPlan,
    'document_pitch_deck': pitchDeck,
    'document_marketing_strategy': marketingStrategy,
    'document_swot_analysis': swotAnalysis,
    'document_financial_forecast': financialForecast,
    'document_executive_summary': executiveSummary,
  };

  // Get price for a tool
  static double getPrice(String toolId) {
    return priceMap[toolId] ?? 0.0;
  }

  // Check if a tool is free
  static bool isFree(String toolId) {
    return getPrice(toolId) == 0.0;
  }

  // Get price tier for a tool (for UI display)
  static String getPriceTier(String toolId) {
    final price = getPrice(toolId);

    if (price == 0.0) {
      return 'Free';
    } else if (price <= 15.0) {
      return 'Basic';
    } else if (price <= 30.0) {
      return 'Standard';
    } else {
      return 'Premium';
    }
  }

  // Get color for price tier
  static Color getPriceTierColor(String toolId) {
    final tier = getPriceTier(toolId);

    switch (tier) {
      case 'Free':
        return Colors.green;
      case 'Basic':
        return Colors.blue;
      case 'Standard':
        return Colors.orange;
      case 'Premium':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
