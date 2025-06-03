import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderService _orderService = OrderService();

  // Function to show status update dialog
  void _showStatusUpdateDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cập nhật trạng thái đơn hàng #${order.id.substring(0, 6)}...'), // Translated title
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Example statuses. You can customize this list.
                _buildStatusOption(context, order, 'Đang chờ xử lý', 'Đang chờ xử lý'),
                _buildStatusOption(context, order, 'Đang chuẩn bị', 'Đang chuẩn bị'),
                _buildStatusOption(context, order, 'Đã hoàn thành', 'Đã hoàn thành'),
                _buildStatusOption(context, order, 'Đã hủy', 'Đã hủy'),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper widget for status options in dialog
  Widget _buildStatusOption(BuildContext context, OrderModel order, String statusValue, String statusText) {
    return InkWell(
      onTap: () async {
        try {
          await _orderService.updateOrderStatus(order.id, statusValue);
          if (!mounted) return; // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng #${order.id.substring(0, 6)} sang ${statusText}')), // Translated success message
          );
          Navigator.of(context).pop(); // Close dialog
        } catch (e) {
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')), // Translated error message
           );
           Navigator.of(context).pop(); // Close dialog
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(statusText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải đơn hàng: ${snapshot.error}')); // Translated error message
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có đơn hàng nào.')); // Translated empty state
        }

        final orders = snapshot.data!;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text('Đơn hàng #${order.id.substring(0, 6)}...'), // Translated title
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng cộng: ${order.totalAmount.toStringAsFixed(0)}₫'), // Changed from \\\$ to ₫ and removed .00
                    Text('Trạng thái: ${order.status}'), // Translated status label (status value remains English for logic)
                    Text('Thời gian: ${order.orderTime.toLocal().toString().split(' ')[0]}'), // Display date only
                    // TODO: Display more order details if needed
                  ],
                ),
                trailing: IconButton(
                   icon: const Icon(Icons.edit),
                   onPressed: () {
                     _showStatusUpdateDialog(order); // Show dialog to update status
                   },
                ),
                onTap: () {
                   // TODO: Navigate to Order Detail Screen (optional)
                },
              ),
            );
          },
        );
      },
    );
  }
} 