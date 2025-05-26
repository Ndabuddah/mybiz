import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../api/gemini_service.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class ContentWriterScreen extends StatefulWidget {
  const ContentWriterScreen({Key? key}) : super(key: key);

  @override
  State<ContentWriterScreen> createState() => _ContentWriterScreenState();
}

class _ContentWriterScreenState extends State<ContentWriterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();

  Business? _selectedBusiness;
  String _contentType = 'Social Media Post';
  String _generatedContent = '';
  bool _isLoading = false;
  bool _isContentGenerated = false;

  final List<String> _contentTypes = ['Social Media Post', 'Blog Article', 'Email Newsletter', 'Product Description', 'Website Copy', 'Ad Copy', 'Press Release'];

  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      setState(() {
        _selectedBusiness = businessProvider.selectedBusiness ?? (businessProvider.businesses.isNotEmpty ? businessProvider.businesses[0] : null);
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isContentGenerated = false;
    });

    try {
      final prompt = '''
Generate ${_contentType.toLowerCase()} for a ${_selectedBusiness!.industry} business named "${_selectedBusiness!.name}".

Business Description: ${_selectedBusiness!.description}

User Instructions: ${_promptController.text}

Create compelling content that aligns with the brand's voice and effectively conveys the message. The content should be professional, engaging, and tailored to the target audience.
''';

      final response = await _geminiService.generateBusinessContent(prompt);

      setState(() {
        _generatedContent = response;
        _isContentGenerated = true;
      });
    } catch (e) {
      Helpers.showSnackBar(context, 'Error generating content: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedContent));
    if (mounted) {
      Helpers.showSnackBar(context, 'Content copied to clipboard');
    }
  }

  void _resetForm() {
    setState(() {
      _promptController.clear();
      _generatedContent = '';
      _isContentGenerated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Content Writer', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(child: Form(key: _formKey, child: _isContentGenerated ? _buildGeneratedContentView(isDarkMode) : _buildContentGeneratorForm(isDarkMode, businessProvider))),
    );
  }

  Widget _buildContentGeneratorForm(bool isDarkMode, BusinessProvider businessProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro text
          Text('Generate professional marketing content for your business using AI', style: AppStyles.bodyLarge(isDarkMode: isDarkMode)),
          const SizedBox(height: 24),

          // Business selection
          Text('Business', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Business>(
                value: _selectedBusiness,
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                hint: Text('Select Business', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45)),
                items:
                    businessProvider.businesses.map((Business business) {
                      return DropdownMenuItem<Business>(value: business, child: Text(business.name));
                    }).toList(),
                onChanged: (Business? value) {
                  setState(() {
                    _selectedBusiness = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content type
          Text('Content Type', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _contentType,
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                items:
                    _contentTypes.map((String type) {
                      return DropdownMenuItem<String>(value: type, child: Text(type));
                    }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _contentType = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prompt
          Text('Your Instructions', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _promptController,
            hintText: 'Describe what content you need...',
            prefixIcon: Icons.edit,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your instructions';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Generate button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Generate Content', icon: Icons.auto_awesome, isLoading: _isLoading, onPressed: _generateContent, type: ButtonType.primary)),

          const SizedBox(height: 24),

          // Examples
          Text('Example Prompts', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),
          _buildExampleCard(isDarkMode, 'Social Media Post', 'Create an engaging post announcing our upcoming summer sale with 30% off all products.'),
          const SizedBox(height: 12),
          _buildExampleCard(isDarkMode, 'Blog Article', 'Write a 500-word blog post about the benefits of sustainable practices in our industry.'),
          const SizedBox(height: 12),
          _buildExampleCard(isDarkMode, 'Email Newsletter', 'Draft a monthly newsletter introducing our new product line and highlighting customer testimonials.'),
        ],
      ),
    );
  }

  Widget _buildGeneratedContentView(bool isDarkMode) {
    return Column(
      children: [
        // Content type header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(_contentType, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), if (_selectedBusiness != null) Text('For: ${_selectedBusiness!.name}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14))],
          ),
        ),

        // Generated content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                  child: Text(_generatedContent, style: TextStyle(fontSize: 16, height: 1.5)),
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
          child: Row(children: [Expanded(child: CustomButton(text: 'Create New', icon: Icons.refresh, onPressed: _resetForm, type: ButtonType.outline)), const SizedBox(width: 16), Expanded(child: CustomButton(text: 'Copy', icon: Icons.copy, onPressed: _copyToClipboard, type: ButtonType.primary))]),
        ),
      ],
    );
  }

  Widget _buildExampleCard(bool isDarkMode, String title, String description) {
    return InkWell(
      onTap: () {
        setState(() {
          _contentType = title;
          _promptController.text = description;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: Text('Tap to use', style: TextStyle(fontSize: 12, color: AppColors.primaryColor, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}
