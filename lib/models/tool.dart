enum ToolCategory { financial, marketing, legal, general }

class Tool {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isPremium;
  final double price;
  final ToolCategory category;

  Tool({required this.id, required this.name, required this.description, required this.icon, required this.color, required this.isPremium, required this.price, required this.category});

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(id: json['id'], name: json['name'], description: json['description'], icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'), color: Color(json['colorValue']), isPremium: json['isPremium'], price: json['price'].toDouble(), category: ToolCategory.values[json['category']]);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'iconCodePoint': icon.codePoint, 'colorValue': color.value, 'isPremium': isPremium, 'price': price, 'category': category.index};
  }
}

// Predefined tools list
List<Tool> predefinedTools = [
  Tool(id: 'invoice_generator', name: 'Invoice Generator', description: 'Create professional invoices', icon: Icons.receipt, color: Colors.green, isPremium: false, price: 0, category: ToolCategory.financial),
  Tool(id: 'budget_builder', name: 'Budget Builder', description: 'Plan your finances', icon: Icons.account_balance_wallet, color: Colors.green, isPremium: false, price: 0, category: ToolCategory.financial),
  Tool(id: 'profit_forecast', name: 'Profit Forecast', description: 'Project your earnings', icon: Icons.trending_up, color: Colors.green, isPremium: true, price: 35, category: ToolCategory.financial),
  Tool(id: 'tax_calculator', name: 'Tax Calculator', description: 'Estimate tax liability', icon: Icons.calculate, color: Colors.green, isPremium: true, price: 25, category: ToolCategory.financial),
  Tool(id: 'marketing_plan', name: 'Marketing Plan', description: 'Create strategic plans', icon: Icons.campaign, color: Colors.blue, isPremium: false, price: 0, category: ToolCategory.marketing),
  Tool(id: 'audience_finder', name: 'Audience Finder', description: 'Identify target market', icon: Icons.people, color: Colors.blue, isPremium: true, price: 30, category: ToolCategory.marketing),
  Tool(id: 'content_writer', name: 'Content Writer', description: 'AI-powered copywriting', icon: Icons.edit, color: Colors.blue, isPremium: true, price: 20, category: ToolCategory.marketing),
  Tool(id: 'social_planner', name: 'Social Planner', description: 'Create social strategies', icon: Icons.share, color: Colors.blue, isPremium: true, price: 40, category: ToolCategory.marketing),
  Tool(id: 'contract_maker', name: 'Contract Maker', description: 'Create legal agreements', icon: Icons.gavel, color: Colors.purple, isPremium: false, price: 0, category: ToolCategory.legal),
  Tool(id: 'ip_checker', name: 'IP Checker', description: 'Trademark & IP guidance', icon: Icons.verified, color: Colors.purple, isPremium: true, price: 45, category: ToolCategory.legal),
  Tool(id: 'privacy_policy', name: 'Privacy Policy', description: 'Generate legal documents', icon: Icons.privacy_tip, color: Colors.purple, isPremium: false, price: 0, category: ToolCategory.legal),
  Tool(id: 'legal_advisor', name: 'Legal Advisor', description: 'AI legal guidance', icon: Icons.balance, color: Colors.purple, isPremium: true, price: 50, category: ToolCategory.legal),
  Tool(id: 'business_plan', name: 'Business Plan', description: 'Create a business plan', icon: Icons.business, color: Colors.orange, isPremium: true, price: 15, category: ToolCategory.general),
  Tool(id: 'pitch_deck', name: 'Pitch Deck', description: 'Create investor pitch', icon: Icons.slideshow, color: Colors.orange, isPremium: true, price: 10, category: ToolCategory.general),
];
