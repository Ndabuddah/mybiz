import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paystack_flutter/paystack_flutter.dart';

class PaystackService {
  static const String secretKey = 'sk_live_50be0cff4e564295a8723aa3c8432d805895e248';

  Future<bool> processPayment(BuildContext context, {required String email, required double amount, required String toolId, required String toolName, required Function onSuccess}) async {
    try {
      await PaystackFlutter().pay(
        context: context,
        secretKey: secretKey,
        amount: (amount * 100).toInt(), // Amount in cents
        email: email,
        callbackUrl: 'https://callback.com',
        showProgressBar: true,
        paymentOptions: [PaymentOption.card, PaymentOption.bankTransfer, PaymentOption.mobileMoney],
        currency: Currency.ZAR,
        metaData: {"tool_id": toolId, "tool_name": toolName, "tool_price": amount},
        onSuccess: (paystackCallback) async {
          // Get today's date in the format YYYY-MM-DD
          String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

          // Prepare payment data to store in Firestore
          Map<String, dynamic> paymentData = {'tool_id': toolId, 'tool_name': toolName, 'payment_amount': amount, 'payment_reference': paystackCallback.reference, 'email': email, 'date': DateTime.now()};

          // Store payment details in Firestore under the current date's collection
          try {
            await FirebaseFirestore.instance.collection('payments').doc(formattedDate).collection('transactions').add(paymentData);

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction Successful: ${paystackCallback.reference}'), backgroundColor: Colors.green));

            onSuccess();
            return true;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error storing payment: $e'), backgroundColor: Colors.red));
            return false;
          }
        },
        onCancelled: (paystackCallback) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction Failed/Not successful: ${paystackCallback.reference}'), backgroundColor: Colors.red));
          return false;
        },
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $e'), backgroundColor: Colors.red));
      return false;
    }
  }
}
