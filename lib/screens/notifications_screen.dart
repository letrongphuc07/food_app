import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  final NotificationService _notificationService = NotificationService();

  NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có thông báo nào'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] as bool? ?? false;

              return Dismissible(
                key: Key(doc.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(doc.id)
                      .delete();
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey : Theme.of(context).primaryColor,
                    child: Icon(
                      _getStatusIcon(data['status'] as String?),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(data['message'] as String? ?? ''),
                  subtitle: Text(
                    _formatTimestamp(data['timestamp'] as Timestamp?),
                    style: TextStyle(
                      color: isRead ? Colors.grey : null,
                    ),
                  ),
                  onTap: () async {
                    if (!isRead) {
                      await _notificationService.markNotificationAsRead(doc.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Processing':
        return Icons.restaurant;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
} 