import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

class SubscriptionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPremium = false;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  DateTime? _premiumEndDate;

  bool get isPremium => _isPremium;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime? get premiumEndDate => _premiumEndDate;

  SubscriptionProvider() {
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Get user document
      final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        _isPremium = userData?['isPremium'] ?? false;

        if (_isPremium && userData?['premiumEndDate'] != null) {
          _premiumEndDate = (userData!['premiumEndDate'] as Timestamp).toDate();
        }
      }

      // Load user transactions
      final snapshot = await _firestore.collection('transactions').where('userId', isEqualTo: _auth.currentUser!.uid).orderBy('date', descending: true).get();

      _transactions = snapshot.docs.map((doc) => TransactionModel.fromJson({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      debugPrint('Error loading subscription data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> upgradeToPremium({required int monthsDuration}) async {
    if (_auth.currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final userId = _auth.currentUser!.uid;
      final now = DateTime.now();

      // Calculate end date based on current premium status
      DateTime endDate;
      if (_isPremium && _premiumEndDate != null && _premiumEndDate!.isAfter(now)) {
        // Extend existing subscription
        endDate = DateTime(_premiumEndDate!.year, _premiumEndDate!.month + monthsDuration, _premiumEndDate!.day);
      } else {
        // New subscription
        endDate = DateTime(now.year, now.month + monthsDuration, now.day);
      }

      // Update user document
      await _firestore.collection('users').doc(userId).update({'isPremium': true, 'premiumEndDate': Timestamp.fromDate(endDate)});

      // Create transaction record
      final transactionId = _firestore.collection('transactions').doc().id;
      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        amount: monthsDuration == 1 ? 99.99 : (monthsDuration == 6 ? 499.99 : 899.99),
        date: now,
        type: 'premium_subscription',
        description: '$monthsDuration month${monthsDuration > 1 ? 's' : ''} Premium Subscription',
        status: 'completed',
      );

      await _firestore.collection('transactions').doc(transactionId).set(transaction.toJson());

      _isPremium = true;
      _premiumEndDate = endDate;
      _transactions.insert(0, transaction);

      return true;
    } catch (e) {
      debugPrint('Error upgrading to premium: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelPremium() async {
    if (_auth.currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({'isPremium': false, 'premiumEndDate': null});

      _isPremium = false;
      _premiumEndDate = null;

      return true;
    } catch (e) {
      debugPrint('Error canceling premium: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String getRemainingDays() {
    if (_premiumEndDate == null) return '0';

    final now = DateTime.now();
    final difference = _premiumEndDate!.difference(now).inDays;

    return difference > 0 ? difference.toString() : '0';
  }
}
