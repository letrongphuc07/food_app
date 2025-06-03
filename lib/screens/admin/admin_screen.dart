import 'package:flutter/material.dart';
import 'package:food_app/screens/admin/food_management_screen.dart'; // Import FoodManagementScreen
import 'package:food_app/screens/admin/order_management_screen.dart'; // Import the new order management screen
import 'package:food_app/screens/admin/user_management_screen.dart'; // Import UserManagementScreen

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Reset length to 3
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Món ăn'),
            Tab(text: 'Đơn hàng'),
            Tab(text: 'Người dùng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FoodManagementScreen(),
          OrderManagementScreen(),
          UserManagementScreen(),
        ],
      ),
    );
  }
} 