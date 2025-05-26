import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/business.dart';
import '../../providers/business_provider.dart';
import '../../utils/helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class BusinessDetailsScreen extends StatefulWidget {
  final Business business;

  const BusinessDetailsScreen({Key? key, required this.business}) : super(key: key);

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late String _selectedIndustry;
  File? _logoFile;
  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> _industries = ['Technology', 'Retail', 'Food & Beverage', 'Healthcare', 'Education', 'Finance', 'Manufacturing', 'Construction', 'Transportation', 'Entertainment', 'Real Estate', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController = TextEditingController(text: widget.business.description);
    _selectedIndustry = widget.business.industry;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);

      if (image != null) {
        setState(() {
          _logoFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Helpers.showSnackBar(context, 'Failed to pick image. Please try again.', isError: true);
    }
  }

  Future<void> _updateBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);

      final success = await businessProvider.updateBusiness(businessId: widget.business.id, name: _nameController.text.trim(), industry: _selectedIndustry, description: _descriptionController.text.trim(), logoFile: _logoFile);

      if (success && mounted) {
        Helpers.showSnackBar(context, 'Business updated successfully!');

        setState(() {
          _isEditing = false;
        });
      } else if (mounted) {
        Helpers.showSnackBar(context, 'Failed to update business. Please try again.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBusiness() async {
    final confirmed = await Helpers.showConfirmDialog(context, 'Delete Business', 'Are you sure you want to delete ${widget.business.name}? This action cannot be undone.', confirmText: 'Delete', cancelText: 'Cancel');

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);

      final success = await businessProvider.deleteBusiness(widget.business.id);

      if (success && mounted) {
        Helpers.showSnackBar(context, 'Business deleted successfully!');

        Navigator.pop(context);
      } else if (mounted) {
        Helpers.showSnackBar(context, 'Failed to delete business. Please try again.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Business' : 'Business Details', style: AppStyles.h2(isDarkMode: isDarkMode)),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          if (!_isEditing) IconButton(onPressed: _deleteBusiness, icon: const Icon(Icons.delete), tooltip: 'Delete'),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Center(
                          child: GestureDetector(
                            onTap: _isEditing ? _pickImage : null,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white10 : Colors.grey[200],
                                shape: BoxShape.circle,
                                image:
                                    _logoFile != null
                                        ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover)
                                        : widget.business.logo != null
                                        ? DecorationImage(image: NetworkImage(widget.business.logo!), fit: BoxFit.cover)
                                        : null,
                              ),
                              child: _logoFile == null && widget.business.logo == null ? Center(child: Text(widget.business.name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white54 : Colors.black38))) : null,
                            ),
                          ),
                        ),
                        if (_isEditing) Center(child: TextButton(onPressed: _pickImage, child: Text('Change Logo', style: TextStyle(color: AppColors.primaryColor)))),
                        const SizedBox(height: 24),

                        // Business name
                        Text('Business Name', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        if (_isEditing)
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'Enter business name',
                            prefixIcon: Icons.business,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a business name';
                              }
                              return null;
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [Icon(Icons.business, color: isDarkMode ? Colors.white54 : Colors.black45), const SizedBox(width: 12), Expanded(child: Text(widget.business.name, style: TextStyle(fontSize: 16)))]),
                          ),
                        const SizedBox(height: 16),

                        // Industry
                        Text('Industry', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        if (_isEditing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedIndustry,
                                isExpanded: true,
                                dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                                icon: const Icon(Icons.arrow_drop_down),
                                items:
                                    _industries.map((String industry) {
                                      return DropdownMenuItem<String>(value: industry, child: Text(industry));
                                    }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedIndustry = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [Icon(Icons.category, color: isDarkMode ? Colors.white54 : Colors.black45), const SizedBox(width: 12), Expanded(child: Text(widget.business.industry, style: TextStyle(fontSize: 16)))]),
                          ),
                        const SizedBox(height: 16),

                        // Description
                        Text('Description', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        if (_isEditing)
                          CustomTextField(
                            controller: _descriptionController,
                            hintText: 'Describe your business',
                            prefixIcon: Icons.description,
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Padding(padding: const EdgeInsets.only(top: 2.0), child: Icon(Icons.description, color: isDarkMode ? Colors.white54 : Colors.black45)), const SizedBox(width: 12), Expanded(child: Text(widget.business.description, style: TextStyle(fontSize: 16)))],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Created at
                        if (!_isEditing) ...[
                          Text('Created On', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [Icon(Icons.calendar_today, color: isDarkMode ? Colors.white54 : Colors.black45), const SizedBox(width: 12), Expanded(child: Text(Helpers.formatDate(widget.business.createdAt), style: TextStyle(fontSize: 16)))]),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Buttons
                        if (_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Cancel',
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      _nameController.text = widget.business.name;
                                      _descriptionController.text = widget.business.description;
                                      _selectedIndustry = widget.business.industry;
                                      _logoFile = null;
                                    });
                                  },
                                  type: ButtonType.outline,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: CustomButton(text: 'Save', icon: Icons.save, isLoading: _isLoading, onPressed: _updateBusiness, type: ButtonType.primary)),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Generate Business Plan',
                              icon: Icons.description,
                              onPressed: () {
                                // Navigate to business plan generator
                              },
                              type: ButtonType.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
