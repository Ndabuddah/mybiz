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

class ContractMakerScreen extends StatefulWidget {
  const ContractMakerScreen({Key? key}) : super(key: key);

  @override
  State<ContractMakerScreen> createState() => _ContractMakerScreenState();
}

class _ContractMakerScreenState extends State<ContractMakerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _termsController = TextEditingController();

  Business? _selectedBusiness;
  String _contractType = 'Service Agreement';
  String _generatedContract = '';
  bool _isLoading = false;
  bool _isContractGenerated = false;

  final List<String> _contractTypes = ['Service Agreement', 'Employment Contract', 'Non-Disclosure Agreement', 'Sales Contract', 'Consulting Agreement', 'Partnership Agreement'];

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
    _clientNameController.dispose();
    _projectNameController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _generateContract() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isContractGenerated = false;
    });

    try {
      final prompt = '''
Create a professional ${_contractType} between ${_selectedBusiness!.name} and ${_clientNameController.text} for the project "${_projectNameController.text}".

Business Description: ${_selectedBusiness!.description}
Project Description: ${_descriptionController.text}
Special Terms: ${_termsController.text}

Generate a complete and legally-formatted contract that includes all necessary sections such as parties, scope of work, payment terms, intellectual property rights, confidentiality, termination, and dispute resolution.

Format the output as a clean, structured legal document with proper headings and clauses. This is for informational purposes only and not legal advice.
''';

      final response = await _geminiService.generateBusinessContent(prompt);

      setState(() {
        _generatedContract = response;
        _isContractGenerated = true;
      });
    } catch (e) {
      Helpers.showSnackBar(context, 'Error generating contract: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedContract));
    if (mounted) {
      Helpers.showSnackBar(context, 'Contract copied to clipboard');
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
            return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(_selectedBusiness!.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Text('Contract', style: pw.TextStyle(fontSize: 16))]);
          },
          footer: (pw.Context context) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Generated with MyBiz', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)), pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600))],
            );
          },
          build: (pw.Context context) {
            return [pw.Center(child: pw.Text(_contractType.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))), pw.SizedBox(height: 20), pw.Text(_generatedContract, style: pw.TextStyle(fontSize: 12, lineSpacing: 1.5))];
          },
        ),
      );

      // Save to file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/${_contractType.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isLoading = false;
      });

      // Share file
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], subject: _contractType, text: 'Contract between ${_selectedBusiness!.name} and ${_clientNameController.text}');
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
      _generatedContract = '';
      _isContractGenerated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Contract Maker', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(child: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(key: _formKey, child: _isContractGenerated ? _buildGeneratedContractView(isDarkMode) : _buildContractGeneratorForm(isDarkMode, businessProvider))),
    );
  }

  Widget _buildContractGeneratorForm(bool isDarkMode, BusinessProvider businessProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro text
          Text('Generate professional legal contracts for your business', style: AppStyles.bodyLarge(isDarkMode: isDarkMode)),
          const SizedBox(height: 8),
          Text('These contracts are for informational purposes only and not legal advice.', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 24),

          // Business selection
          Text('Your Business', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
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

          // Contract type
          Text('Contract Type', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _contractType,
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                items:
                    _contractTypes.map((String type) {
                      return DropdownMenuItem<String>(value: type, child: Text(type));
                    }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _contractType = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Client name
          Text('Client/Second Party Name', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _clientNameController,
            hintText: 'Enter client or second party name',
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter client name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Project name
          Text('Project/Agreement Name', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _projectNameController,
            hintText: 'Enter project or agreement name',
            prefixIcon: Icons.work,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter project name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          Text('Description', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _descriptionController,
            hintText: 'Describe the project or work to be done',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Special terms
          Text('Special Terms (Optional)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(controller: _termsController, hintText: 'Enter any special terms or conditions', prefixIcon: Icons.rule, maxLines: 2),
          const SizedBox(height: 32),

          // Generate button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Generate Contract', icon: Icons.gavel, onPressed: _generateContract, type: ButtonType.primary)),

          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Legal Disclaimer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 8),
                Text(
                  'The contracts generated by this tool are templates for informational purposes only and do not constitute legal advice. You should consult with a qualified legal professional before using any contract for official business purposes.',
                  style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedContractView(bool isDarkMode) {
    return Column(
      children: [
        // Contract type header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_contractType, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if (_selectedBusiness != null) Text('Between: ${_selectedBusiness!.name} and ${_clientNameController.text}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
        ),

        // Generated contract
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                  child: Text(_generatedContract, style: TextStyle(fontSize: 16, height: 1.5)),
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
              Expanded(child: CustomButton(text: 'New Contract', icon: Icons.refresh, onPressed: _resetForm, type: ButtonType.outline)),
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
