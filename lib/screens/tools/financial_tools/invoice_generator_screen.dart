import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/helper.dart';
import '../../../utils/pdf_generator.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class InvoiceGeneratorScreen extends StatefulWidget {
  const InvoiceGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceGeneratorScreen> createState() => _InvoiceGeneratorScreenState();
}

class _InvoiceGeneratorScreenState extends State<InvoiceGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _invoiceNumberController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _notesController = TextEditingController();

  Business? _selectedBusiness;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  double _taxRate = 15.0;
  bool _isLoading = false;

  List<Map<String, dynamic>> _items = [
    {'description': '', 'quantity': 1, 'price': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      setState(() {
        _selectedBusiness = businessProvider.selectedBusiness ?? (businessProvider.businesses.isNotEmpty ? businessProvider.businesses[0] : null);
      });
    });
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: isInvoiceDate ? _invoiceDate : _dueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));

    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
          // Update due date to be 15 days after new invoice date
          _dueDate = picked.add(const Duration(days: 15));
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add({'description': '', 'quantity': 1, 'price': 0.0});
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, String field, dynamic value) {
    setState(() {
      _items[index][field] = value;
    });
  }

  double _calculateSubtotal() {
    double subtotal = 0;
    for (var item in _items) {
      subtotal += (item['quantity'] as num) * (item['price'] as num);
    }
    return subtotal;
  }

  double _calculateTax() {
    return _calculateSubtotal() * (_taxRate / 100);
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTax();
  }

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    // Validate items
    bool itemsValid = true;
    for (var item in _items) {
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
      final invoiceFile = await PdfGenerator.generateInvoice(
        business: _selectedBusiness!,
        invoiceNumber: _invoiceNumberController.text,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        clientName: _clientNameController.text,
        clientEmail: _clientEmailController.text,
        clientAddress: _clientAddressController.text,
        items: _items,
        taxRate: _taxRate,
        notes: _notesController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showInvoiceOptions(invoiceFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Helpers.showSnackBar(context, 'Error generating invoice: $e', isError: true);
      }
    }
  }

  void _showInvoiceOptions(File invoiceFile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Invoice Generated', style: AppStyles.h2(isDarkMode: Theme.of(context).brightness == Brightness.dark)),
              const SizedBox(height: 16),
              Text('Your invoice has been generated. What would you like to do with it?', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Share',
                      icon: Icons.share,
                      onPressed: () {
                        Navigator.pop(context);
                        Share.shareXFiles([XFile(invoiceFile.path)], subject: 'Invoice ${_invoiceNumberController.text}', text: 'Please find attached invoice ${_invoiceNumberController.text}');
                      },
                      type: ButtonType.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Create New',
                      icon: Icons.add,
                      onPressed: () {
                        Navigator.pop(context);
                        _resetForm();
                      },
                      type: ButtonType.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      _clientNameController.clear();
      _clientEmailController.clear();
      _clientAddressController.clear();
      _notesController.clear();
      _invoiceDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 15));
      _items = [
        {'description': '', 'quantity': 1, 'price': 0.0},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Invoice Generator', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
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
                        const SizedBox(height: 16),

                        // Invoice details
                        Text('Invoice Details', style: AppStyles.h3(isDarkMode: isDarkMode)),
                        const SizedBox(height: 16),

                        // Invoice number
                        Text('Invoice Number', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _invoiceNumberController,
                          hintText: 'Enter invoice number',
                          prefixIcon: Icons.numbers,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an invoice number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Invoice Date', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                                      child: Row(children: [Icon(Icons.calendar_today, size: 16, color: isDarkMode ? Colors.white54 : Colors.black45), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(_invoiceDate))]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Due Date', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                                      child: Row(children: [Icon(Icons.calendar_today, size: 16, color: isDarkMode ? Colors.white54 : Colors.black45), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(_dueDate))]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Client details
                        Text('Client Details', style: AppStyles.h3(isDarkMode: isDarkMode)),
                        const SizedBox(height: 16),

                        // Client name
                        Text('Client Name', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _clientNameController,
                          hintText: 'Enter client name',
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter client name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Client email
                        Text('Client Email', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _clientEmailController,
                          hintText: 'Enter client email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter client email';
                            }
                            if (!Helpers.isValidEmail(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Client address
                        Text('Client Address', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _clientAddressController,
                          hintText: 'Enter client address',
                          prefixIcon: Icons.location_on,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter client address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Items
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text('Items', style: AppStyles.h3(isDarkMode: isDarkMode)), TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Add Item'), style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor))],
                        ),
                        const SizedBox(height: 8),

                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                              Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Price (R)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                              SizedBox(width: 40),
                            ],
                          ),
                        ),

                        // Items list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  // Description
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: _items[index]['description'] as String,
                                      decoration: InputDecoration(hintText: 'Item description', hintStyle: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white38 : Colors.black38), border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                      style: TextStyle(fontSize: 14),
                                      onChanged: (value) {
                                        _updateItem(index, 'description', value);
                                      },
                                    ),
                                  ),

                                  // Quantity
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: _items[index]['quantity'].toString(),
                                      decoration: InputDecoration(hintText: 'Qty', hintStyle: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white38 : Colors.black38), border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                      style: TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _updateItem(index, 'quantity', int.tryParse(value) ?? 1);
                                      },
                                    ),
                                  ),

                                  // Price
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: _items[index]['price'].toString(),
                                      decoration: InputDecoration(hintText: 'Price', hintStyle: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white38 : Colors.black38), border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                      style: TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _updateItem(index, 'price', double.tryParse(value) ?? 0.0);
                                      },
                                    ),
                                  ),

                                  // Delete button
                                  SizedBox(width: 40, child: _items.length > 1 ? IconButton(onPressed: () => _removeItem(index), icon: Icon(Icons.delete, color: Colors.red, size: 20), padding: EdgeInsets.zero, constraints: BoxConstraints()) : SizedBox()),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Tax rate
                        Row(
                          children: [
                            Text('Tax Rate (%)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Slider(
                                value: _taxRate,
                                min: 0,
                                max: 30,
                                divisions: 30,
                                label: _taxRate.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _taxRate = value;
                                  });
                                },
                                activeColor: AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(width: 40, child: Text('${_taxRate.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Totals
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtotal:'), Text('R${_calculateSubtotal().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold))]),
                              const SizedBox(height: 8),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tax (${_taxRate.toStringAsFixed(0)}%):'), Text('R${_calculateTax().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold))]),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('R${_calculateTotal().toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor))],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Notes
                        Text('Notes (Optional)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        CustomTextField(controller: _notesController, hintText: 'Add any notes or payment instructions', prefixIcon: Icons.note, maxLines: 3),

                        const SizedBox(height: 32),

                        // Generate button
                        SizedBox(width: double.infinity, child: CustomButton(text: 'Generate Invoice', icon: Icons.receipt, onPressed: _generateInvoice, type: ButtonType.primary)),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
