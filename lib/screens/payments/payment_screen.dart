import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/paystack_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String toolId;
  final String toolName;
  final VoidCallback onSuccess;

  const PaymentScreen({Key? key, required this.amount, required this.toolId, required this.toolName, required this.onSuccess}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaystackService _paystackService = PaystackService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Payment', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Summary', style: AppStyles.h3(isDarkMode: isDarkMode)),
                    const SizedBox(height: 16),
                    _buildDetailRow('Tool', widget.toolName, isDarkMode),
                    _buildDetailRow('Amount', 'R${widget.amount.toStringAsFixed(2)}', isDarkMode),
                    _buildDetailRow('User', user?.email ?? '', isDarkMode),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('R${widget.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryColor))],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Payment method
              Text('Payment Method', style: AppStyles.h3(isDarkMode: isDarkMode)),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  children: [
                    _buildPaymentMethodTile('Credit/Debit Card', Icons.credit_card, true, isDarkMode),
                    const Divider(),
                    _buildPaymentMethodTile('Bank Transfer', Icons.account_balance, false, isDarkMode),
                    const Divider(),
                    _buildPaymentMethodTile('Mobile Money', Icons.phone_android, false, isDarkMode),
                  ],
                ),
              ),

              const Spacer(),

              // Terms and conditions
              Text('By proceeding with the payment, you agree to our Terms and Conditions and Privacy Policy.', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black54), textAlign: TextAlign.center),

              const SizedBox(height: 16),

              // Payment button
              SizedBox(width: double.infinity, child: CustomButton(text: 'Pay R${widget.amount.toStringAsFixed(2)}', icon: Icons.lock, isLoading: _isLoading, onPressed: () => _processPayment(context, user?.email ?? ''), type: ButtonType.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)), Text(value, style: TextStyle(fontWeight: FontWeight.w500))]));
  }

  Widget _buildPaymentMethodTile(String title, IconData icon, bool isSelected, bool isDarkMode) {
    return Row(
      children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: isDarkMode ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54)),
        const SizedBox(width: 16),
        Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Radio(
          value: true,
          groupValue: isSelected,
          onChanged: (value) {
            // Handle payment method selection
          },
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Future<void> _processPayment(BuildContext context, String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User email is required'), backgroundColor: AppColors.error));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _paystackService.processPayment(context, email: email, amount: widget.amount, toolId: widget.toolId, toolName: widget.toolName, onSuccess: widget.onSuccess);

      if (success) {
        // Payment handled in the callback
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment error: $e'), backgroundColor: AppColors.error));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
