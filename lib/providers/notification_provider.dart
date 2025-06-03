import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart' as local_auth_provider; // Assuming AuthProvider is in the same directory
import 'dart:async'; // Import dart:async for StreamSubscription

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final local_auth_provider.AuthProvider _authProvider;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  NotificationProvider(this._authProvider) {
    _authProvider.addListener(_userAuthStateChanged);
    _userAuthStateChanged(); // Initial check
  }

  void _userAuthStateChanged() {
    if (_authProvider.isAuthenticated && _authProvider.user != null) {
      _startListening(_authProvider.user!.id);
    } else {
      _stopListening();
    }
  }

  void _startListening(String userId) {
    _stopListening(); // Stop any existing listener
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _unreadCount = snapshot.docs.length;
      notifyListeners();
    }, onError: (error) {
      print('Error listening to notifications: $error');
      // Optionally handle error, e.g., set count to 0 and notify
      _unreadCount = 0;
      notifyListeners();
    });
  }

  void _stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _unreadCount = 0; // Reset count when not authenticated or user changes
    notifyListeners();
  }

  @override
  void dispose() {
    _stopListening();
    _authProvider.removeListener(_userAuthStateChanged);
    super.dispose();
  }
} 