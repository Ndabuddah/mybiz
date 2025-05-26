import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _revenueController = TextEditingController();
  final _expensesController = TextEditingController();
  final _otherIncomeController = TextEditingController();
  final _deductionsController = TextEditingController();

  Business? _selectedBusiness;
  String _businessType = 'Sole Proprietor';
  String _taxYear = '2023/2024';

  bool _isLoading = false;
  bool _isCalculated = false;

  // Tax calculation results
  double _taxableIncome = 0;
  double _taxAmount = 0;
  double _effectiveTaxRate = 0;

  final List<String> _businessTypes = ['Sole Proprietor', 'Partnership', 'Private Company (Pty)', 'Close Corporation'];

  final List<String> _taxYears = ['2023/2024', '2022/2023', '2021/2022'];

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
    _revenueController.dispose();
    _expensesController.dispose();
    _otherIncomeController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  Future<void> _calculateTax() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final revenue = double.parse(_revenueController.text.replaceAll(',', ''));
      final expenses = double.parse(_expensesController.text.replaceAll(',', ''));
      final otherIncome = _otherIncomeController.text.isEmpty ? 0.0 : double.parse(_otherIncomeController.text.replaceAll(',', ''));
      final deductions = _deductionsController.text.isEmpty ? 0.0 : double.parse(_deductionsController.text.replaceAll(',', ''));

      // Calculate taxable income
      final businessProfit = revenue - expenses;
      final taxableIncome = businessProfit + otherIncome - deductions;

      // Calculate tax based on business type and tax year
      double taxAmount = 0;

      if (_businessType == 'Private Company (Pty)' || _businessType == 'Close Corporation') {
        // Corporate tax rate - 28% for companies
        taxAmount = taxableIncome * 0.28;
      } else {
        // Progressive tax rate for individuals (simplified)
        if (taxableIncome <= 226000) {
          taxAmount = taxableIncome * 0.18;
        } else if (taxableIncome <= 353100) {
          taxAmount = 40680 + (taxableIncome - 226000) * 0.26;
        } else if (taxableIncome <= 488700) {
          taxAmount = 73726 + (taxableIncome - 353100) * 0.31;
        } else if (taxableIncome <= 641400) {
          taxAmount = 115762 + (taxableIncome - 488700) * 0.36;
        } else if (taxableIncome <= 817600) {
          taxAmount = 170734 + (taxableIncome - 641400) * 0.39;
        } else if (taxableIncome <= 1731600) {
          taxAmount = 239452 + (taxableIncome - 817600) * 0.41;
        } else {
          taxAmount = 614192 + (taxableIncome - 1731600) * 0.45;
        }
      }

      // Calculate effective tax rate
      final effectiveTaxRate = taxableIncome > 0 ? (taxAmount / taxableIncome) * 100 : 0;

      // Update state with results
      setState(() {
        _taxableIncome = taxableIncome;
        _taxAmount = taxAmount;
        _effectiveTaxRate = effectiveTaxRate;
        _isCalculated = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      Helpers.showSnackBar(context, 'Error calculating tax: $e', isError: true);
    }
  }

  void _resetForm() {
    setState(() {
      _revenueController.clear();
      _expensesController.clear();
      _otherIncomeController.clear();
      _deductionsController.clear();
      _isCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Tax Calculator', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isCalculated
                  ? _buildTaxResults(isDarkMode)
                  : _buildTaxForm(isDarkMode, businessProvider),
        ),
      ),
    );
  }

  Widget _buildTaxForm(bool isDarkMode, BusinessProvider businessProvider) {
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
                Expanded(child: Text('This calculator provides estimates only and should not be used for filing taxes. Consult a tax professional for advice.', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54))),
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

          // Tax parameters
          Row(
            children: [
              // Business type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Business Type', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _businessType,
                          isExpanded: true,
                          dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                          items:
                              _businessTypes.map((String type) {
                                return DropdownMenuItem<String>(value: type, child: Text(type, style: TextStyle(fontSize: 14)));
                              }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _businessType = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Tax year
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tax Year', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _taxYear,
                          isExpanded: true,
                          dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                          items:
                              _taxYears.map((String year) {
                                return DropdownMenuItem<String>(value: year, child: Text(year, style: TextStyle(fontSize: 14)));
                              }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _taxYear = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Income section
          Text('Income', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),

          // Revenue
          Text('Annual Revenue (R)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _revenueController,
            hintText: 'Enter total revenue',
            prefixIcon: Icons.payments,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter revenue';
              }
              if (double.tryParse(value.replaceAll(',', '')) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Expenses
          Text('Annual Expenses (R)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _expensesController,
            hintText: 'Enter total expenses',
            prefixIcon: Icons.receipt_long,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter expenses';
              }
              if (double.tryParse(value.replaceAll(',', '')) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Other income
          Text('Other Income (R) - Optional', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _otherIncomeController,
            hintText: 'Enter other income (if any)',
            prefixIcon: Icons.add_chart,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null; // Optional field
              }
              if (double.tryParse(value.replaceAll(',', '')) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Deductions section
          Text('Deductions', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),

          // Tax deductions
          Text('Tax Deductions (R) - Optional', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _deductionsController,
            hintText: 'Enter tax deductions (if any)',
            prefixIcon: Icons.remove_circle_outline,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null; // Optional field
              }
              if (double.tryParse(value.replaceAll(',', '')) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Calculate button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Calculate Tax', icon: Icons.calculate, onPressed: _calculateTax, type: ButtonType.primary)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTaxResults(bool isDarkMode) {
    final formattedTaxableIncome = Helpers.formatCurrency(_taxableIncome);
    final formattedTaxAmount = Helpers.formatCurrency(_taxAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tax summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppStyles.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text('Tax Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(_taxYear, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text('Taxable Income', style: TextStyle(color: Colors.white.withOpacity(0.8))), const SizedBox(height: 4), Text(formattedTaxableIncome, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))],
                    ),
                    Container(height: 50, width: 1, color: Colors.white.withOpacity(0.3)),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Tax Amount', style: TextStyle(color: Colors.white.withOpacity(0.8))), const SizedBox(height: 4), Text(formattedTaxAmount, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))]),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                  child: Text('Effective Tax Rate: ${_effectiveTaxRate.toStringAsFixed(2)}%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business details
          if (_selectedBusiness != null) ...[
            Text('Business Details', style: AppStyles.h3(isDarkMode: isDarkMode)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_selectedBusiness!.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Text(_businessType, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                      ),
                    ],
                  ),
                  Text(_selectedBusiness!.industry, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Income breakdown
          Text('Income Breakdown', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              children: [
                _buildBreakdownRow('Revenue', _revenueController.text.isEmpty ? 'R0.00' : 'R${double.parse(_revenueController.text.replaceAll(',', '')).toStringAsFixed(2)}', isDarkMode),
                _buildBreakdownRow('Expenses', _expensesController.text.isEmpty ? 'R0.00' : '-R${double.parse(_expensesController.text.replaceAll(',', '')).toStringAsFixed(2)}', isDarkMode, isNegative: true),
                _buildBreakdownRow('Business Profit', 'R${(_taxableIncome - (double.tryParse(_otherIncomeController.text.replaceAll(',', '')) ?? 0) + (double.tryParse(_deductionsController.text.replaceAll(',', '')) ?? 0)).toStringAsFixed(2)}', isDarkMode, isSubtotal: true),
                const SizedBox(height: 8),
                _buildBreakdownRow('Other Income', _otherIncomeController.text.isEmpty ? 'R0.00' : 'R${double.parse(_otherIncomeController.text.replaceAll(',', '')).toStringAsFixed(2)}', isDarkMode),
                _buildBreakdownRow('Deductions', _deductionsController.text.isEmpty ? 'R0.00' : '-R${double.parse(_deductionsController.text.replaceAll(',', '')).toStringAsFixed(2)}', isDarkMode, isNegative: true),
                const Divider(),
                _buildBreakdownRow('Taxable Income', 'R${_taxableIncome.toStringAsFixed(2)}', isDarkMode, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tax calculation
          Text('Tax Calculation', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              children: [
                _buildBreakdownRow('Taxable Income', 'R${_taxableIncome.toStringAsFixed(2)}', isDarkMode),
                _buildBreakdownRow('Tax Rate', _businessType == 'Private Company (Pty)' || _businessType == 'Close Corporation' ? '28% (Flat rate)' : 'Progressive', isDarkMode),
                const Divider(),
                _buildBreakdownRow('Tax Amount', 'R${_taxAmount.toStringAsFixed(2)}', isDarkMode, isTotal: true),
                _buildBreakdownRow('Effective Tax Rate', '${_effectiveTaxRate.toStringAsFixed(2)}%', isDarkMode),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Recalculate',
                  icon: Icons.refresh,
                  onPressed: () {
                    setState(() {
                      _isCalculated = false;
                    });
                  },
                  type: ButtonType.outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: CustomButton(text: 'New Calculation', icon: Icons.add, onPressed: _resetForm, type: ButtonType.primary)),
            ],
          ),

          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(isDarkMode ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
            child: Column(
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: Colors.orange), const SizedBox(width: 12), Expanded(child: Text('Disclaimer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)))]),
                const SizedBox(height: 8),
                Text(
                  'This tax calculation is an estimate only and should not be used for filing taxes. Tax laws and rates may change, and individual circumstances can affect tax liability. Consult a professional tax advisor for accurate tax advice.',
                  style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, bool isDarkMode, {bool isSubtotal = false, bool isTotal = false, bool isNegative = false}) {
    Color valueColor =
        isNegative
            ? Colors.red
            : isTotal
            ? AppColors.primaryColor
            : isDarkMode
            ? Colors.white
            : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isSubtotal || isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: isSubtotal || isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: valueColor)),
        ],
      ),
    );
  }
}
