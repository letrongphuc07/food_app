import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'orders';
  final NotificationService _notificationService = NotificationService();

  // Get all orders
  Stream<List<OrderModel>> getOrders() {
    return _firestore
        .collection(_collection)
        .orderBy('orderTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  // Get orders by user ID
  Stream<List<OrderModel>> getOrdersByUserId(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('orderTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  // Get order by ID
  Future<OrderModel> getOrderById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists) {
        throw Exception('Order not found');
      }

      return OrderModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Create new order
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final DocumentReference docRef = await _firestore.collection(_collection).add(order.toJson());
      return order.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String id, String status) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'Đã hoàn thành') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      // Get order details before updating
      final orderDoc = await _firestore.collection(_collection).doc(id).get();
      final orderData = orderDoc.data();
      final userId = orderData?['userId'] as String?;

      // Update order status
      await _firestore.collection(_collection).doc(id).update(updateData);

      // Send notification if user ID exists
      if (userId != null) {
        String message = '';
        switch (status) {
          case 'Đang chờ xử lý':
            message = 'Đơn hàng #${id.substring(0, 6)} của bạn đang chờ xử lý';
            break;
          case 'Đang chuẩn bị':
            message = 'Đơn hàng #${id.substring(0, 6)} của bạn đang được chuẩn bị';
            break;
          case 'Đã hoàn thành':
            message = 'Đơn hàng #${id.substring(0, 6)} của bạn đã hoàn thành';
            break;
          case 'Đã bị hủy':
            message = 'Đơn hàng #${id.substring(0, 6)} của bạn đã bị hủy';
            break;
        }

        await _notificationService.sendOrderStatusNotification(
          userId: userId,
          orderId: id,
          status: status,
          message: message,
        );
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Delete order
  Future<void> deleteOrder(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // Get orders by status
  Stream<List<OrderModel>> getOrdersByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('orderTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      final List<OrderModel> orders = snapshot.docs
          .map((doc) => OrderModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      double totalRevenue = 0;
      int totalOrders = orders.length;
      Map<String, int> statusCount = {
        'Pending': 0,
        'Processing': 0,
        'Completed': 0,
        'Cancelled': 0,
      };

      for (var order in orders) {
        if (order.status == 'Completed') {
          totalRevenue += order.totalAmount;
        }
        statusCount[order.status] = (statusCount[order.status] ?? 0) + 1;
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'statusCount': statusCount,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }

  // Get daily revenue
  Future<List<Map<String, dynamic>>> getDailyRevenue() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'Completed')
          .get();

      final List<OrderModel> orders = snapshot.docs
          .map((doc) => OrderModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      Map<String, double> dailyRevenue = {};

      for (var order in orders) {
        if (order.deliveredAt != null) {
          final date = order.deliveredAt!.toLocal().toString().split(' ')[0];
          dailyRevenue[date] = (dailyRevenue[date] ?? 0) + order.totalAmount;
        }
      }

      return dailyRevenue.entries
          .map((e) => {
                'date': e.key,
                'revenue': e.value,
              })
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    } catch (e) {
      throw Exception('Failed to get daily revenue: $e');
    }
  }

  // Place a new order
  Future<void> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').add(order.toJson());
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  // Get orders for a specific user (optional - for user history)
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => OrderModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            })).toList());
  }

  // Get all orders (for admin)
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => OrderModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            })).toList());
  }
} 