import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Gửi thông báo cho người dùng
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String status,
    required String message,
  }) async {
    try {
      // Lấy token của người dùng từ Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userToken = userDoc.data()?['fcmToken'];

      if (userToken != null) {
        // Lưu thông báo vào collection notifications
        await _firestore.collection('notifications').add({
          'userId': userId,
          'orderId': orderId,
          'status': status,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Gửi thông báo push notification
        await _messaging.sendMessage(
          to: userToken,
          data: {
            'title': 'Cập nhật đơn hàng',
            'body': message,
            'orderId': orderId,
            'status': status,
          },
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  // Lấy danh sách thông báo của người dùng
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
} 