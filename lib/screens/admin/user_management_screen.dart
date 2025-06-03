import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to show add/edit user dialog
  void _showUserDialog([UserModel? user]) {
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _selectedRole = user.role;
      _isActive = user.isActive;
    } else {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedRole = 'user';
      _isActive = true;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user == null ? 'Thêm người dùng mới' : 'Sửa thông tin người dùng'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  if (user == null)
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Mật khẩu'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                      DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Tài khoản đang hoạt động'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    if (user == null) {
                      // Add new user
                      final userCredential = await _authService.registerWithEmailAndPassword(
                        _nameController.text,
                        _emailController.text,
                        _passwordController.text,
                      );
                      await _firestore.collection('users').doc(userCredential.id).set({
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'role': _selectedRole,
                        'isActive': _isActive,
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      // Update existing user
                      await _firestore.collection('users').doc(user.id).update({
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'role': _selectedRole,
                        'isActive': _isActive,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    }
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(user == null ? 'Đã thêm người dùng mới' : 'Đã cập nhật thông tin người dùng'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  // Function to show delete confirmation dialog
  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa người dùng ${user.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestore.collection('users').doc(user.id).delete();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa người dùng')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải danh sách người dùng: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có người dùng nào.'));
          }

          final users = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserModel.fromJson({
              ...data,
              'id': doc.id,
            });
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${user.email}'),
                      Text('Vai trò: ${user.role == 'admin' ? 'Quản trị viên' : 'Người dùng'}'),
                      Text('Trạng thái: ${user.isActive ? 'Đang hoạt động' : 'Đã khóa'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showUserDialog(user),
                        tooltip: 'Sửa thông tin',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteConfirmation(user),
                        tooltip: 'Xóa người dùng',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Thêm người dùng mới',
      ),
    );
  }
} 