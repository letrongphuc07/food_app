import 'package:flutter/material.dart';
import 'package:food_app/screens/admin/food_management_screen.dart'; // Import FoodManagementScreen
import 'package:food_app/screens/admin/order_management_screen.dart'; // Import the new order management screen
import 'package:food_app/screens/admin/user_management_screen.dart'; // Import UserManagementScreen
import 'package:food_app/screens/stats_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Reset tab controller to first tab (Food Management)
              _tabController.animateTo(0);
            },
            tooltip: 'Trang chính',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
            tooltip: 'Thống kê',
          ),
        ],
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