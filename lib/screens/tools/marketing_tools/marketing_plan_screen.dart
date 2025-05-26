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

class MarketingPlanScreen extends StatefulWidget {
  const MarketingPlanScreen({Key? key}) : super(key: key);

  @override
  State<MarketingPlanScreen> createState() => _MarketingPlanScreenState();
}

class _MarketingPlanScreenState extends State<MarketingPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetAudienceController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _budgetController = TextEditingController();
  final _timeframeController = TextEditingController();

  Business? _selectedBusiness;
  List<String> _selectedChannels = [];
  String _generatedPlan = '';
  bool _isLoading = false;
  bool _isPlanGenerated = false;

  final List<Map<String, dynamic>> _marketingChannels = [
    {'name': 'Social Media', 'icon': Icons.public},
    {'name': 'Email Marketing', 'icon': Icons.email},
    {'name': 'Content Marketing', 'icon': Icons.article},
    {'name': 'SEO', 'icon': Icons.search},
    {'name': 'PPC Advertising', 'icon': Icons.money},
    {'name': 'Influencer Marketing', 'icon': Icons.person},
    {'name': 'Events', 'icon': Icons.event},
    {'name': 'PR', 'icon': Icons.campaign},
  ];

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
    _targetAudienceController.dispose();
    _objectivesController.dispose();
    _budgetController.dispose();
    _timeframeController.dispose();
    super.dispose();
  }

  Future<void> _generateMarketingPlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    if (_selectedChannels.isEmpty) {
      Helpers.showSnackBar(context, 'Please select at least one marketing channel', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isPlanGenerated = false;
    });

    try {
      final prompt = '''
Create a detailed marketing plan for a ${_selectedBusiness!.industry} business named "${_selectedBusiness!.name}".

Business Description: ${_selectedBusiness!.description}

Target Audience: ${_targetAudienceController.text}
Marketing Objectives: ${_objectivesController.text}
Marketing Budget: ${_budgetController.text}
Timeframe: ${_timeframeController.text}
Selected Marketing Channels: ${_selectedChannels.join(', ')}

Generate a comprehensive marketing plan that includes strategy, tactics, timeline, budget allocation, and KPIs for each selected marketing channel. The plan should be specific, actionable, and aligned with the business objectives.
''';

      final response = await _geminiService.generateBusinessContent(prompt);

      setState(() {
        _generatedPlan = response;
        _isPlanGenerated = true;
      });
    } catch (e) {
      Helpers.showSnackBar(context, 'Error generating marketing plan: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedPlan));
    if (mounted) {
      Helpers.showSnackBar(context, 'Marketing plan copied to clipboard');
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
            return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(_selectedBusiness!.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Text('Marketing Plan', style: pw.TextStyle(fontSize: 16))]);
          },
          footer: (pw.Context context) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Generated with MyBiz', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)), pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600))],
            );
          },
          build: (pw.Context context) {
            return [pw.Center(child: pw.Text('MARKETING PLAN', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))), pw.SizedBox(height: 20), pw.Text(_generatedPlan, style: pw.TextStyle(fontSize: 12, lineSpacing: 1.5))];
          },
        ),
      );

      // Save to file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Marketing_Plan_${_selectedBusiness!.name.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isLoading = false;
      });

      // Share file
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], subject: 'Marketing Plan for ${_selectedBusiness!.name}');
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
      _targetAudienceController.clear();
      _objectivesController.clear();
      _budgetController.clear();
      _timeframeController.clear();
      _selectedChannels = [];
      _generatedPlan = '';
      _isPlanGenerated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Marketing Plan', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(child: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(key: _formKey, child: _isPlanGenerated ? _buildGeneratedPlanView(isDarkMode) : _buildPlanGeneratorForm(isDarkMode, businessProvider))),
    );
  }

  Widget _buildPlanGeneratorForm(bool isDarkMode, BusinessProvider businessProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Target audience
          Text('Target Audience', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _targetAudienceController,
            hintText: 'Describe your target audience',
            prefixIcon: Icons.people,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your target audience';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Marketing objectives
          Text('Marketing Objectives', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _objectivesController,
            hintText: 'Enter your marketing objectives',
            prefixIcon: Icons.flag,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your marketing objectives';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Marketing budget
          Text('Marketing Budget', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _budgetController,
            hintText: 'Enter your marketing budget (e.g., R5,000/month)',
            prefixIcon: Icons.account_balance_wallet,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your marketing budget';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Timeframe
          Text('Timeframe', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _timeframeController,
            hintText: 'Enter timeframe (e.g., 3 months, Q1 2023)',
            prefixIcon: Icons.calendar_today,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a timeframe';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Marketing channels
          Text('Marketing Channels', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 8),
          Text('Select the marketing channels you want to include in your plan:', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 16),

          // Channel selection
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _marketingChannels.map((channel) {
                  final isSelected = _selectedChannels.contains(channel['name']);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedChannels.remove(channel['name']);
                        } else {
                          _selectedChannels.add(channel['name']);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryColor : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isSelected ? AppColors.primaryColor : (isDarkMode ? Colors.white24 : Colors.black12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(channel['icon'], size: 16, color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black54)), const SizedBox(width: 8), Text(channel['name'], style: TextStyle(color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black)))],
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 32),

          // Generate button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Generate Marketing Plan', icon: Icons.create, onPressed: _generateMarketingPlan, type: ButtonType.primary)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGeneratedPlanView(bool isDarkMode) {
    return Column(
      children: [
        // Marketing plan header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('Marketing Plan', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), if (_selectedBusiness != null) Text('For: ${_selectedBusiness!.name}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14))],
          ),
        ),

        // Generated plan
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                  child: Text(_generatedPlan, style: TextStyle(fontSize: 16, height: 1.5)),
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
              Expanded(child: CustomButton(text: 'New Plan', icon: Icons.refresh, onPressed: _resetForm, type: ButtonType.outline)),
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
