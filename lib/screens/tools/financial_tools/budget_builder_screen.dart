import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class BudgetBuilderScreen extends StatefulWidget {
  const BudgetBuilderScreen({Key? key}) : super(key: key);

  @override
  State<BudgetBuilderScreen> createState() => _BudgetBuilderScreenState();
}

class _BudgetBuilderScreenState extends State<BudgetBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _periodController = TextEditingController();

  Business? _selectedBusiness;
  List<Map<String, dynamic>> _incomeItems = [
    {'description': '', 'amount': 0.0},
  ];
  List<Map<String, dynamic>> _expenseItems = [
    {'description': '', 'amount': 0.0},
  ];

  bool _isLoading = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _periodController.text = DateFormat('MMMM yyyy').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      setState(() {
        _selectedBusiness = businessProvider.selectedBusiness ?? (businessProvider.businesses.isNotEmpty ? businessProvider.businesses[0] : null);
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _addIncomeItem() {
    setState(() {
      _incomeItems.add({'description': '', 'amount': 0.0});
    });
  }

  void _removeIncomeItem(int index) {
    setState(() {
      _incomeItems.removeAt(index);
    });
  }

  void _addExpenseItem() {
    setState(() {
      _expenseItems.add({'description': '', 'amount': 0.0});
    });
  }

  void _removeExpenseItem(int index) {
    setState(() {
      _expenseItems.removeAt(index);
    });
  }

  void _updateIncomeItem(int index, String field, dynamic value) {
    setState(() {
      _incomeItems[index][field] = value;
    });
  }

  void _updateExpenseItem(int index, String field, dynamic value) {
    setState(() {
      _expenseItems[index][field] = value;
    });
  }

  double _calculateTotalIncome() {
    double total = 0;
    for (var item in _incomeItems) {
      total += item['amount'] as double;
    }
    return total;
  }

  double _calculateTotalExpenses() {
    double total = 0;
    for (var item in _expenseItems) {
      total += item['amount'] as double;
    }
    return total;
  }

  double _calculateNetIncome() {
    return _calculateTotalIncome() - _calculateTotalExpenses();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    // Validate items
    bool itemsValid = true;
    for (var item in _incomeItems) {
      if (item['description'].toString().trim().isEmpty) {
        itemsValid = false;
        break;
      }
    }

    for (var item in _expenseItems) {
      if (item['description'].toString().trim().isEmpty) {
        itemsValid = false;
        break;
      }
    }

    if (!itemsValid) {
      Helpers.showSnackBar(context, 'Please fill in all item descriptions', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate saving to database
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
        _isSaved = true;
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Budget saved successfully!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Error saving budget: $e', isError: true);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _periodController.text = DateFormat('MMMM yyyy').format(DateTime.now());
      _incomeItems = [
        {'description': '', 'amount': 0.0},
      ];
      _expenseItems = [
        {'description': '', 'amount': 0.0},
      ];
      _isSaved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Budget Builder', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isSaved
                  ? _buildBudgetSummary(isDarkMode)
                  : _buildBudgetForm(isDarkMode, businessProvider),
        ),
      ),
    );
  }

  Widget _buildBudgetForm(bool isDarkMode, BusinessProvider businessProvider) {
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

          // Budget details
          Text('Budget Details', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),

          // Budget title
          Text('Budget Title', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _titleController,
            hintText: 'Enter budget title',
            prefixIcon: Icons.title,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a budget title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Budget period
          Text('Budget Period', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _periodController,
            hintText: 'Enter budget period (e.g., January 2023)',
            prefixIcon: Icons.calendar_today,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a budget period';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Income section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Income', style: AppStyles.h3(isDarkMode: isDarkMode)), TextButton.icon(onPressed: _addIncomeItem, icon: const Icon(Icons.add), label: const Text('Add Income'), style: TextButton.styleFrom(foregroundColor: Colors.green))],
          ),
          const SizedBox(height: 8),

          // Income items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _incomeItems.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: _incomeItems[index]['description'] as String,
                        decoration: InputDecoration(hintText: 'Income source', border: InputBorder.none),
                        onChanged: (value) {
                          _updateIncomeItem(index, 'description', value);
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: (_incomeItems[index]['amount'] as double).toString(),
                        decoration: InputDecoration(hintText: 'Amount', prefixText: 'R ', border: InputBorder.none),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        onChanged: (value) {
                          _updateIncomeItem(index, 'amount', double.tryParse(value) ?? 0.0);
                        },
                      ),
                    ),
                    _incomeItems.length > 1 ? IconButton(onPressed: () => _removeIncomeItem(index), icon: Icon(Icons.delete, color: Colors.red), padding: EdgeInsets.zero) : SizedBox(width: 40),
                  ],
                ),
              );
            },
          ),

          // Income total
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(isDarkMode ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Total Income', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), Text('R ${_calculateTotalIncome().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))],
            ),
          ),

          // Expenses section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Expenses', style: AppStyles.h3(isDarkMode: isDarkMode)), TextButton.icon(onPressed: _addExpenseItem, icon: const Icon(Icons.add), label: const Text('Add Expense'), style: TextButton.styleFrom(foregroundColor: Colors.red))],
          ),
          const SizedBox(height: 8),

          // Expense items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _expenseItems.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: _expenseItems[index]['description'] as String,
                        decoration: InputDecoration(hintText: 'Expense description', border: InputBorder.none),
                        onChanged: (value) {
                          _updateExpenseItem(index, 'description', value);
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: (_expenseItems[index]['amount'] as double).toString(),
                        decoration: InputDecoration(hintText: 'Amount', prefixText: 'R ', border: InputBorder.none),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        onChanged: (value) {
                          _updateExpenseItem(index, 'amount', double.tryParse(value) ?? 0.0);
                        },
                      ),
                    ),
                    _expenseItems.length > 1 ? IconButton(onPressed: () => _removeExpenseItem(index), icon: Icon(Icons.delete, color: Colors.red), padding: EdgeInsets.zero) : SizedBox(width: 40),
                  ],
                ),
              );
            },
          ),

          // Expense total
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Total Expenses', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), Text('R ${_calculateTotalExpenses().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))],
            ),
          ),

          // Net income
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Net Income', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('R ${_calculateNetIncome().toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _calculateNetIncome() >= 0 ? Colors.green : Colors.red))],
            ),
          ),

          // Save button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Save Budget', icon: Icons.save, onPressed: _saveBudget, type: ButtonType.primary)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(isDarkMode ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text('Budget Saved!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)), Text('Your budget has been saved successfully.', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54))],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Budget header
          Text(_titleController.text.isEmpty ? 'Budget' : _titleController.text, style: AppStyles.h2(isDarkMode: isDarkMode)),
          Text(_periodController.text, style: AppStyles.bodyLarge(isDarkMode: isDarkMode).copyWith(color: isDarkMode ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 16),

          // Business info
          if (_selectedBusiness != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
                boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: AppColors.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text(_selectedBusiness!.name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryColor))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_selectedBusiness!.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(_selectedBusiness!.industry, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54))])),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Budget summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
              boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Income summary
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Income', style: TextStyle(fontWeight: FontWeight.w500)), Text('R ${_calculateTotalIncome().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                const SizedBox(height: 8),

                // Expense summary
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Expenses', style: TextStyle(fontWeight: FontWeight.w500)), Text('R ${_calculateTotalExpenses().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),

                Divider(height: 24),

                // Net income
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Net Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('R ${_calculateNetIncome().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _calculateNetIncome() >= 0 ? Colors.green : Colors.red))],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Income details
          Text('Income Details', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
              boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                for (var item in _incomeItems)
                  Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item['description'] as String), Text('R ${(item['amount'] as double).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500))])),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Expense details
          Text('Expense Details', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
              boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                for (var item in _expenseItems)
                  Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item['description'] as String), Text('R ${(item['amount'] as double).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w500))])),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit Budget',
                  icon: Icons.edit,
                  onPressed: () {
                    setState(() {
                      _isSaved = false;
                    });
                  },
                  type: ButtonType.outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: CustomButton(text: 'New Budget', icon: Icons.add, onPressed: _resetForm, type: ButtonType.primary)),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
