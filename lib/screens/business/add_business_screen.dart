import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/business_provider.dart';
import '../../utils/helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddBusinessScreen extends StatefulWidget {
  const AddBusinessScreen({Key? key}) : super(key: key);

  @override
  State<AddBusinessScreen> createState() => _AddBusinessScreenState();
}

class _AddBusinessScreenState extends State<AddBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedIndustry = 'Technology';
  File? _logoFile;
  bool _isLoading = false;

  final List<String> _industries = ['Technology', 'Retail', 'Food & Beverage', 'Healthcare', 'Education', 'Finance', 'Manufacturing', 'Construction', 'Transportation', 'Entertainment', 'Real Estate', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
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

  Future<void> _addBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);

      final business = await businessProvider.addBusiness(name: _nameController.text.trim(), industry: _selectedIndustry, description: _descriptionController.text.trim(), logoFile: _logoFile);

      if (business != null && mounted) {
        Helpers.showSnackBar(context, 'Business added successfully!');

        Navigator.pop(context);
      } else if (mounted) {
        Helpers.showSnackBar(context, 'Failed to add business. Please try again.', isError: true);
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
      appBar: AppBar(title: Text('Add Business', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo upload
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(color: isDarkMode ? Colors.white10 : Colors.grey[200], shape: BoxShape.circle, image: _logoFile != null ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover) : null),
                      child: _logoFile == null ? Icon(Icons.add_a_photo, size: 40, color: isDarkMode ? Colors.white54 : Colors.black38) : null,
                    ),
                  ),
                ),
                Center(child: TextButton(onPressed: _pickImage, child: Text(_logoFile == null ? 'Add Logo (Optional)' : 'Change Logo', style: TextStyle(color: AppColors.primaryColor)))),
                const SizedBox(height: 24),

                // Business name
                Text('Business Name', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
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
                ),
                const SizedBox(height: 16),

                // Industry dropdown
                Text('Industry', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
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
                ),
                const SizedBox(height: 16),

                // Description
                Text('Description', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
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
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(width: double.infinity, child: CustomButton(text: 'Add Business', icon: Icons.add_business, isLoading: _isLoading, onPressed: _addBusiness, type: ButtonType.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
