import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('Starting sign in process...');
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;

      if (user == null) {
        throw Exception('User not found');
      }

      print('Firebase Auth successful for user: ${user.uid}');
      
      // Get user data from Firestore
      print('Fetching user data from Firestore...');
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      print('Firestore document exists: ${doc.exists}');
      print('Firestore document data: ${doc.data()}');

      if (!doc.exists) {
        print('User document not found in Firestore');
        throw Exception('User data not found');
      }

      final data = doc.data();
      print('Raw Firestore data type: ${data.runtimeType}');
      
      if (data is! Map<String, dynamic>) {
        print('Invalid data type in Firestore: ${data.runtimeType}');
        throw Exception('Invalid user data format');
      }

      final userData = Map<String, dynamic>.from(data);
      userData['id'] = user.uid;
      
      print('Processed user data: $userData');

      // Update last login
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error during sign in: $e');
      print('Error type: ${e.runtimeType}');
      if (e is TypeError) {
        print('TypeError details: ${e.toString()}');
      }
      throw Exception('Failed to sign in: $e');
    }
  }

  // Register with email and password
  Future<UserModel> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      print('Starting registration process...');
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;

      if (user == null) {
        throw Exception('Failed to create user');
      }

      print('Firebase Auth user created: ${user.uid}');

      // Create user data in Firestore
      final userData = {
        'id': user.uid,
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      print('Writing user data to Firestore: $userData');

      try {
        await _firestore.collection('users').doc(user.uid).set(userData);
        print('User data successfully written to Firestore');
      } catch (e) {
        print('Error writing to Firestore: $e');
        await user.delete();
        print('Deleted auth user due to Firestore write failure');
        throw Exception('Failed to save user data: $e');
      }

      final DocumentSnapshot newUserDoc = await _firestore.collection('users').doc(user.uid).get();
      final newUserData = newUserDoc.data() as Map<String, dynamic>;
      newUserData['id'] = user.uid;

      return UserModel.fromJson(newUserData);

    } catch (e) {
      print('Registration error: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Failed to register: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user data
  Future<UserModel> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      print('Firestore doc exists for user $userId: ${doc.exists}');
      if (doc.exists) {
        print('Firestore doc data: ${doc.data()}');
      }

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      final data = doc.data();
      print('Raw Firestore data type in getUserData: ${data.runtimeType}');

      if (data is! Map<String, dynamic>) {
        print('Invalid data type in getUserData: ${data.runtimeType}');
        throw Exception('Invalid user data format in getUserData');
      }

      final userData = Map<String, dynamic>.from(data);
      userData['id'] = userId;

      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
} 