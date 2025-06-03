import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';

  // Initialize auth state
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print('Fetching user data for ${currentUser.uid}...');
        _user = await _authService.getUserData(currentUser.uid);
        print('User data fetched: ${_user?.email}');
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      print('User signed in: ${_user?.email}');
      print('Attempting to fetch user data after sign-in...');
      _user = await _authService.getUserData(_authService.currentUser!.uid);
      print('User data fetched after sign-in: ${_user?.email}');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register
  Future<void> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.registerWithEmailAndPassword(name, email, password);
      print('User registered: ${_user?.email}');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserData(_user!.id, data);
      _user = await _authService.getUserData(_user!.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 