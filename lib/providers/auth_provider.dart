import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import '../models/user.dart' as app_models;

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  app_models.User? _currentUser;
  bool _isLoading = false;

  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        await _fetchUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        _currentUser = app_models.User.fromJson({...docSnapshot.data()!, 'uid': uid});
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        final newUser = app_models.User(uid: result.user!.uid, email: email, name: name, isPremium: false, purchasedTools: [], createdAt: DateTime.now());

        await _firestore.collection('users').doc(result.user!.uid).set(newUser.toJson());

        _currentUser = newUser;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during registration: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        await _fetchUserData(result.user!.uid);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  Future<bool> upgradeSubscription() async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(_currentUser!.uid).update({'isPremium': true});

      _currentUser = _currentUser!.copyWith(isPremium: true);
      return true;
    } catch (e) {
      debugPrint('Error upgrading subscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchaseTool(String toolId) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final updatedPurchasedTools = [..._currentUser!.purchasedTools, toolId];

      await _firestore.collection('users').doc(_currentUser!.uid).update({'purchasedTools': updatedPurchasedTools});

      _currentUser = _currentUser!.copyWith(purchasedTools: updatedPurchasedTools);
      return true;
    } catch (e) {
      debugPrint('Error purchasing tool: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool hasAccessToTool(String toolId) {
    if (_currentUser == null) return false;

    // Check if user is premium or has purchased the tool
    return _currentUser!.isPremium || _currentUser!.purchasedTools.contains(toolId);
  }
}
