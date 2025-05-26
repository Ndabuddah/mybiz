import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../api/gemini_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/business.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../utils/helper.dart';
import '../../utils/pdf_generator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../payments/payment_screen.dart';

class DocumentGeneratorScreen extends StatefulWidget {
  const DocumentGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<DocumentGeneratorScreen> createState() => _DocumentGeneratorScreenState();
}

class _DocumentGeneratorScreenState extends State<DocumentGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();

  Business? _selectedBusiness;
  String _documentType = 'Business Plan';
  String _generatedDocument = '';
  bool _isLoading = false;
  bool _isDocumentGenerated = false;

  final Map<String, Map<String, dynamic>> _documentTypes = {
    'Business Plan': {'icon': Icons.business, 'price': 15.0, 'description': 'A comprehensive business plan including executive summary, market analysis, financial projections, and more.'},
    'Pitch Deck': {'icon': Icons.slideshow, 'price': 10.0, 'description': 'A concise presentation to pitch your business idea to potential investors or partners.'},
    'Marketing Strategy': {'icon': Icons.campaign, 'price': 12.0, 'description': 'A detailed marketing plan with target audience analysis, promotional strategies, and budget allocation.'},
    'SWOT Analysis': {'icon': Icons.analytics, 'price': 5.0, 'description': 'An analysis of your business\'s Strengths, Weaknesses, Opportunities, and Threats.'},
    'Financial Forecast': {'icon': Icons.trending_up, 'price': 12.0, 'description': 'Detailed financial projections including revenue, expenses, profit margins, and break-even analysis.'},
    'Executive Summary': {'icon': Icons.summarize, 'price': 5.0, 'description': 'A concise overview of your business, its mission, products/services, and goals.'},
  };

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

  Future<void> _generateDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // Check if user has already purchased this tool
    final hasAccess = user != null && (user.isPremium || user.purchasedTools.contains('document_${_documentType.toLowerCase().replaceAll(' ', '_')}'));

    if (!hasAccess) {
      // Show payment screen
      final documentPrice = _documentTypes[_documentType]!['price'] as double;

      final navigator = Navigator.of(context);
      final result = await navigator.push(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            amount: documentPrice,
            toolId: 'document_${_documentType.toLowerCase().replaceAll(' ', '_')}',
            toolName: _documentType,
            onSuccess: () async {
              final success = await authProvider.purchaseTool('document_${_documentType.toLowerCase().replaceAll(' ', '_')}');
              if (success) {
                ScaffoldMessenger.of(navigator.context).showSnackBar(SnackBar(content: Text('Successfully purchased $_documentType generator!'), backgroundColor: AppColors.success));
              }
            },
          ),
        ),
      );

      if (result != true) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _isDocumentGenerated = false;
    });

    try {
      final prompt = '''
Create a professional ${_documentType} for a ${_selectedBusiness!.industry} business named "${_selectedBusiness!.name}".

Business Description: ${_selectedBusiness!.description}

Additional Instructions: ${_promptController.text}

Create a comprehensive, detailed, and professional document that is ready for presentation to stakeholders, investors, or partners. Include all relevant sections appropriate for this type of document.
''';

      final response = await _geminiService.generateBusinessContent(prompt);

      setState(() {
        _generatedDocument = response;
        _isDocumentGenerated = true;
      });
    } catch (e) {
      Helpers.showSnackBar(context, 'Error generating document: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedDocument));
    if (mounted) {
      Helpers.showSnackBar(context, 'Document copied to clipboard');
    }
  }

  Future<void> _downloadAsPdf() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Generate PDF
      final file = await PdfGenerator.generateBusinessPlan(business: _selectedBusiness!, planContent: _generatedDocument);

      setState(() {
        _isLoading = false;
      });

      // Share file
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], subject: '$_documentType for ${_selectedBusiness!.name}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Error creating PDF: $e', isError: true);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _generatedDocument = '';
      _isDocumentGenerated = false;
      _promptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Document Generator', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(child: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(key: _formKey, child: _isDocumentGenerated ? _buildGeneratedDocumentView(isDarkMode) : _buildDocumentGeneratorForm(isDarkMode, businessProvider))),
    );
  }

  Widget _buildDocumentGeneratorForm(bool isDarkMode, BusinessProvider businessProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro text
          Text('Generate professional business documents with AI', style: AppStyles.bodyLarge(isDarkMode: isDarkMode)),
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
                items: businessProvider.businesses.map((Business business) {
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
          const SizedBox(height: 24),

          // Document type selection
          Text('Document Type', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 16, mainAxisSpacing: 16),
            itemCount: _documentTypes.length,
            itemBuilder: (context, index) {
              final docType = _documentTypes.keys.elementAt(index);
              final docInfo = _documentTypes[docType]!;
              final isSelected = _documentType == docType;

              return InkWell(
                onTap: () {
                  setState(() {
                    _documentType = docType;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1) : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primaryColor : (isDarkMode ? Colors.white24 : Colors.black12), width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(docInfo['icon'] as IconData, color: isSelected ? AppColors.primaryColor : null, size: 32),
                      const SizedBox(height: 8),
                      Text(docType, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primaryColor : null), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('R${docInfo['price'].toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: isSelected ? AppColors.primaryColor : (isDarkMode ? Colors.white70 : Colors.black54)), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Selected document description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(_documentTypes[_documentType]!['icon'] as IconData, color: AppColors.primaryColor, size: 18), const SizedBox(width: 8), Text(_documentType, style: TextStyle(fontWeight: FontWeight.bold))]),
                const SizedBox(height: 8),
                Text(_documentTypes[_documentType]!['description'] as String, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Additional instructions
          Text('Additional Instructions (Optional)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(controller: _promptController, hintText: 'Enter any specific requirements or information...', prefixIcon: Icons.edit_note, maxLines: 3),

          const SizedBox(height: 32),

          // Generate button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Generate $_documentType', icon: Icons.description, onPressed: _generateDocument, type: ButtonType.primary)),

          const SizedBox(height: 16),

          // Price info
          Center(child: Text('One-time cost: R${_documentTypes[_documentType]!['price'].toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildGeneratedDocumentView(bool isDarkMode) {
    return Column(
      children: [
        // Document type header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(_documentType, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), if (_selectedBusiness != null) Text('For: ${_selectedBusiness!.name}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14))],
          ),
        ),

        // Generated document
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                  child: Text(_generatedDocument, style: TextStyle(fontSize: 16, height: 1.5)),
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
          child: Row(
            children: [
              Expanded(child: CustomButton(text: 'New Document', icon: Icons.refresh, onPressed: _resetForm, type: ButtonType.outline)),
              const SizedBox(width: 8),
              Expanded(child: CustomButton(text: 'Copy', icon: Icons.copy, onPressed: _copyToClipboard, type: ButtonType.secondary)),
              const SizedBox(width: 8),
              Expanded(child: CustomButton(text: 'Download', icon: Icons.download, onPressed: _downloadAsPdf, isLoading: _isLoading, type: ButtonType.primary)),
            ],
          ),
        ),
      ],
    );
  }
}
