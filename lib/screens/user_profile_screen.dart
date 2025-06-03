import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
      try {
        final doc = await _firestore.collection('users').doc(_userId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _nameController.text = data['name'] as String? ?? '';
          _genderController.text = data['gender'] as String? ?? '';
          _phoneController.text = data['phone'] as String? ?? '';
          _emailController.text = user.email ?? ''; // Use Firebase Auth email
          _addressController.text = data['address'] as String? ?? '';
        } else {
           // Optionally create a basic user document if it doesn't exist
           await _firestore.collection('users').doc(_userId).set({
             'name': '',
             'gender': '',
             'phone': '',
             'email': user.email, // Save Firebase Auth email
             'address': '',
           });
           _emailController.text = user.email ?? '';
           _addressController.text = '';
        }
      } catch (e) {
        print('Error loading user profile: $e');
        // Show error to user
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserProfile() async {
    if (_userId != null) {
      try {
        await _firestore.collection('users').doc(_userId).update({
          'name': _nameController.text.trim(),
          'gender': _genderController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          // Email is typically managed by Firebase Auth, not updated directly here
        });
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu thông tin cá nhân')));
      } catch (e) {
        print('Error saving user profile: $e');
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu thông tin: ${e}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveUserProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _genderController,
                    decoration: const InputDecoration(labelText: 'Giới tính'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    readOnly: true, // Email is typically read-only
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Địa chỉ'),
                    maxLines: 3, // Allow multiple lines for address
                  ),
                  const SizedBox(height: 24),
                  // Save button is in AppBar actions
                ],
              ),
            ),
    );
  }
} 