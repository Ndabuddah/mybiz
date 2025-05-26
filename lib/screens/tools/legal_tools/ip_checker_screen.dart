import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../api/gemini_service.dart';
import '../../../utils/helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class IPCheckerScreen extends StatefulWidget {
  const IPCheckerScreen({Key? key}) : super(key: key);

  @override
  State<IPCheckerScreen> createState() => _IPCheckerScreenState();
}

class _IPCheckerScreenState extends State<IPCheckerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchTermController = TextEditingController();
  final _descriptionController = TextEditingController();

  Business? _selectedBusiness;
  String _ipType = 'Trademark';
  String _searchResults = '';
  bool _isLoading = false;
  bool _isSearchComplete = false;

  final List<String> _ipTypes = [
    'Trademark',
    'Patent',
    'Copyright',
    'Domain Name',
    'Business Name',
  ];

  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      setState(() {
        _selectedBusiness = businessProvider.selectedBusiness ??
            (businessProvider.businesses.isNotEmpty ? businessProvider.businesses[0] : null);
      });
    });
  }

  @override
  void dispose() {
    _searchTermController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _performIPCheck() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(
        context,
        'Please select a business first',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearchComplete = false;
    });

    try {
      final prompt = '''
Perform an intellectual property check for the ${_ipType.toLowerCase()} "${_searchTermController.text}" for a ${_selectedBusiness!.industry} business named "${_selectedBusiness!.name}".

Description: ${_descriptionController.text}

Please provide a comprehensive analysis of this potential intellectual property, including:

1. Potential conflicts or issues with existing intellectual property
2. Distinctiveness and uniqueness assessment
3. General advice on protectability
4. Recommendations for next steps
5. Key considerations for proper registration and protection

Note: This should simulate a thorough IP check while acknowledging that this is for informational purposes only and not a replacement for professional legal advice or official trademark/patent searches.
''';

      final response = await _geminiService.generateBusinessContent(prompt);

      setState(() {
        _searchResults = response;
        _isSearchComplete = true;
      });
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error performing IP check: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _searchResults));
    if (mounted) {
      Helpers.showSnackBar(
        context,
        'Results copied to clipboard',
      );
    }
  }

  void _resetForm() {
    setState(() {
      _searchTermController.clear();
      _descriptionController.clear();
      _searchResults = '';
      _isSearchComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IP Checker',
          style: AppStyles.h2(isDarkMode: isDarkMode),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: _isSearchComplete
              ? _buildSearchResultsView(isDarkMode)
              : _buildSearchForm(isDarkMode, businessProvider),
        ),
      ),
    );
  }

  Widget _buildSearchForm(bool isDarkMode, BusinessProvider businessProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This tool provides general guidance only and does not replace a professional IP search or legal advice. Results are for informational purposes only.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business selection
          Text(
            'Business',
            style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Business>(
                value: _selectedBusiness,
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                hint: Text(
                  'Select Business',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.black45,
                  ),
                ),
                items: businessProvider.businesses.map((Business business) {
                  return DropdownMenuItem<Business>(
                    value: business,
                    child: Text(business.name),
                  );
                }).toList(),
                onChanged: (Business? value) {
                  setState(() {
                    _selectedBusiness = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // IP Type
          Text(
            'Intellectual Property Type',
            style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _ipType,
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                items: _ipTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _ipType = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search term
          Text(
            'Name / Term to Check',
            style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _searchTermController,
            hintText: 'Enter name or term to check',
            prefixIcon: Icons.search,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name or term to check';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Description',
            style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _descriptionController,
            hintText: 'Describe the product, service, or invention',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // What you'll get
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkCard : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What You\'ll Get',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureItem('Potential conflicts assessment', isDarkMode),
                _buildFeatureItem('Distinctiveness analysis', isDarkMode),
                _buildFeatureItem('Registration recommendations', isDarkMode),
                _buildFeatureItem('Protection strategies', isDarkMode),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Check button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Check Intellectual Property',
              icon: Icons.verified,
              onPressed: _performIPCheck,
              type: ButtonType.primary,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(bool isDarkMode) {
    return Column(
      children: [
        // IP check header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_ipType Check Results',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Term: ${_searchTermController.text}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              if (_selectedBusiness != null)
                Text(
                  'For: ${_selectedBusiness!.name}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        // Generated results
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                    boxShadow: isDarkMode
                        ? []
                        : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _searchResults,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Disclaimer: This IP check is for informational purposes only and should not be considered legal advice. For a comprehensive IP search and protection strategy, consult with a qualified intellectual property attorney.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCard : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'New Check',
                  icon: Icons.refresh,
                  onPressed: _resetForm,
                  type: ButtonType.outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Copy Results',
                  icon: Icons.copy,
                  onPressed: _copyToClipboard,
                  type: ButtonType.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}