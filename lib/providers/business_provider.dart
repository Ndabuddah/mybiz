import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../api/cloudinary_service.dart';
import '../models/business.dart';

class BusinessProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService(cloudName: 'your-cloud-name', uploadPreset: 'your-upload-preset');

  List<Business> _businesses = [];
  bool _isLoading = false;
  Business? _selectedBusiness;

  List<Business> get businesses => _businesses;
  bool get isLoading => _isLoading;
  Business? get selectedBusiness => _selectedBusiness;

  BusinessProvider() {
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    if (_auth.currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore.collection('businesses').where('ownerId', isEqualTo: _auth.currentUser!.uid).get();

      _businesses = snapshot.docs.map((doc) => Business.fromJson({...doc.data(), 'id': doc.id})).toList();

      // Sort businesses by created date (newest first)
      _businesses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (_businesses.isNotEmpty && _selectedBusiness == null) {
        _selectedBusiness = _businesses.first;
      }
    } catch (e) {
      debugPrint('Error loading businesses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectBusiness(Business business) {
    _selectedBusiness = business;
    notifyListeners();
  }

  Future<Business?> addBusiness({required String name, required String industry, required String description, File? logoFile, Map<String, dynamic>? additionalInfo}) async {
    if (_auth.currentUser == null) return null;

    try {
      _isLoading = true;
      notifyListeners();

      // Upload logo to Cloudinary if provided
      String? logoUrl;
      if (logoFile != null) {
        logoUrl = await _cloudinaryService.uploadImage(logoFile);
      }

      final newBusiness = Business(id: const Uuid().v4(), name: name, industry: industry, description: description, logo: logoUrl, ownerId: _auth.currentUser!.uid, createdAt: DateTime.now(), additionalInfo: additionalInfo);

      await _firestore.collection('businesses').doc(newBusiness.id).set(newBusiness.toJson());

      _businesses.add(newBusiness);
      _selectedBusiness = newBusiness;

      return newBusiness;
    } catch (e) {
      debugPrint('Error adding business: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBusiness({required String businessId, String? name, String? industry, String? description, File? logoFile, Map<String, dynamic>? additionalInfo}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final businessIndex = _businesses.indexWhere((b) => b.id == businessId);
      if (businessIndex == -1) return false;

      final business = _businesses[businessIndex];

      // Upload logo to Cloudinary if provided
      String? logoUrl = business.logo;
      if (logoFile != null) {
        logoUrl = await _cloudinaryService.uploadImage(logoFile);
      }

      final updatedBusiness = business.copyWith(name: name ?? business.name, industry: industry ?? business.industry, description: description ?? business.description, logo: logoUrl, additionalInfo: additionalInfo ?? business.additionalInfo);

      await _firestore.collection('businesses').doc(businessId).update({
        if (name != null) 'name': name,
        if (industry != null) 'industry': industry,
        if (description != null) 'description': description,
        if (logoUrl != null) 'logo': logoUrl,
        if (additionalInfo != null) 'additionalInfo': additionalInfo,
      });

      _businesses[businessIndex] = updatedBusiness;

      if (_selectedBusiness?.id == businessId) {
        _selectedBusiness = updatedBusiness;
      }

      return true;
    } catch (e) {
      debugPrint('Error updating business: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBusiness(String businessId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('businesses').doc(businessId).delete();

      _businesses.removeWhere((business) => business.id == businessId);

      if (_selectedBusiness?.id == businessId) {
        _selectedBusiness = _businesses.isNotEmpty ? _businesses.first : null;
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting business: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get business by ID
  Business? getBusinessById(String id) {
    try {
      return _businesses.firstWhere((business) => business.id == id);
    } catch (e) {
      return null;
    }
  }
}
