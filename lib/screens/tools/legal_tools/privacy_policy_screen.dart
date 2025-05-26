import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../api/gemini_service.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _websiteController = TextEditingController();
  final _dataCollectedController = TextEditingController();
  final _contactEmailController = TextEditingController();

  Business? _selectedBusiness;
  bool _collectsPersonalData = true;
  bool _sharesDataWithThirdParties = false;
  bool _usesAnalytics = true;
  bool _usesCookies = true;

  String _generatedPolicy = '';
  bool _isLoading = false;
  bool _isPolicyGenerated = false;

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
    _websiteController.dispose();
    _dataCollectedController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _generatePrivacyPolicy() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isPolicyGenerated = false;
    });

    try {
      final prompt = '''
Create a comprehensive privacy policy for a ${_selectedBusiness!.industry} business named "${_selectedBusiness!.name}".

Website/App: ${_websiteController.text}
Contact Email: ${_contactEmailController.text}
Data Collected: ${_dataCollectedController.text}
Collects Personal Data: ${_collectsPersonalData ? 'Yes' : 'No'}
Shares Data with Third Parties: ${_sharesDataWithThirdParties ? 'Yes' : 'No'}
Uses Analytics: ${_usesAnalytics ? 'Yes' : 'No'}
Uses Cookies: ${_usesCookies ? 'Yes' : 'No'}

Generate a legally-sound privacy policy that addresses all relevant data protection and privacy laws including GDPR and POPIA. The policy should be comprehensive, easy to understand, and include all necessary sections such as data collection practices, user rights, data sharing policies, etc.

Format the output as a clean, structured legal document with proper headings and clauses. This is for informational purposes only and not legal advice.
''';

      final response = await _geminiService.generateBusinessContent(prompt);

      setState(() {
        _generatedPolicy = response;
        _isPolicyGenerated = true;
      });
    } catch (e) {
      Helpers.showSnackBar(context, 'Error generating privacy policy: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedPolicy));
    if (mounted) {
      Helpers.showSnackBar(context, 'Privacy policy copied to clipboard');
    }
  }

  Future<void> _downloadAsPdf() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create PDF document
      final pdf = pw.Document();

      // Add page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(_selectedBusiness!.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Text('Privacy Policy', style: pw.TextStyle(fontSize: 16))]);
          },
          footer: (pw.Context context) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Generated with MyBiz', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)), pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600))],
            );
          },
          build: (pw.Context context) {
            return [
              pw.Center(child: pw.Text('PRIVACY POLICY', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text(_selectedBusiness!.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700))),
              pw.SizedBox(height: 20),
              pw.Text(_generatedPolicy, style: pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
            ];
          },
        ),
      );

      // Save to file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Privacy_Policy_${_selectedBusiness!.name.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isLoading = false;
      });

      // Share file
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], subject: 'Privacy Policy for ${_selectedBusiness!.name}');
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
      _websiteController.clear();
      _dataCollectedController.clear();
      _contactEmailController.clear();
      _collectsPersonalData = true;
      _sharesDataWithThirdParties = false;
      _usesAnalytics = true;
      _usesCookies = true;
      _generatedPolicy = '';
      _isPolicyGenerated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy Generator', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(child: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(key: _formKey, child: _isPolicyGenerated ? _buildGeneratedPolicyView(isDarkMode) : _buildPolicyGeneratorForm(isDarkMode, businessProvider))),
    );
  }

  Widget _buildPolicyGeneratorForm(bool isDarkMode, BusinessProvider businessProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(isDarkMode ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(child: Text('This generator creates a privacy policy template for informational purposes only. Consult with a legal professional before publishing.', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54))),
              ],
            ),
          ),
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
          const SizedBox(height: 24),

          // Website/App URL
          Text('Website or App URL', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _websiteController,
            hintText: 'Enter your website or app URL',
            prefixIcon: Icons.language,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your website or app URL';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Contact email
          Text('Contact Email', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _contactEmailController,
            hintText: 'Enter contact email for privacy inquiries',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a contact email';
              }
              if (!Helpers.isValidEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Data collected
          Text('Data Collected', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _dataCollectedController,
            hintText: 'What data do you collect? (e.g., name, email, address)',
            prefixIcon: Icons.data_array,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe the data you collect';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Data practices
          Text('Data Practices', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),

          // Checkboxes for data practices
          _buildCheckboxTile('Collects Personal Information', 'We collect personal information from users', _collectsPersonalData, (value) {
            setState(() {
              _collectsPersonalData = value ?? true;
            });
          }, isDarkMode),
          _buildCheckboxTile('Shares Data with Third Parties', 'We share user data with third-party service providers', _sharesDataWithThirdParties, (value) {
            setState(() {
              _sharesDataWithThirdParties = value ?? false;
            });
          }, isDarkMode),
          _buildCheckboxTile('Uses Analytics Tools', 'We use analytics tools to track user behavior', _usesAnalytics, (value) {
            setState(() {
              _usesAnalytics = value ?? true;
            });
          }, isDarkMode),
          _buildCheckboxTile('Uses Cookies', 'We use cookies and similar tracking technologies', _usesCookies, (value) {
            setState(() {
              _usesCookies = value ?? true;
            });
          }, isDarkMode),

          const SizedBox(height: 32),

          // Generate button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Generate Privacy Policy', icon: Icons.policy, onPressed: _generatePrivacyPolicy, type: ButtonType.primary)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGeneratedPolicyView(bool isDarkMode) {
    return Column(
      children: [
        // Privacy policy header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy Policy', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if (_selectedBusiness != null) Text('For: ${_selectedBusiness!.name}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              Text('Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ),

        // Generated policy
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                  child: Text(_generatedPolicy, style: TextStyle(fontSize: 16, height: 1.5)),
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
              Expanded(child: CustomButton(text: 'New Policy', icon: Icons.refresh, onPressed: _resetForm, type: ButtonType.outline)),
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

  Widget _buildCheckboxTile(String title, String subtitle, bool value, Function(bool?) onChanged, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
      child: CheckboxListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryColor,
        checkColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
