import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String foodId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;

  OrderItem({
    required this.foodId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodId: json['foodId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String? ?? '',
      quantity: (json['quantity'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderTime;
  final String status; // e.g., 'Pending', 'Processing', 'Completed', 'Cancelled'
  final String? shippingAddress; // Optional
  final DateTime? deliveredAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderTime,
    required this.status,
    this.shippingAddress,
    this.deliveredAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Helper function to parse dynamic fields safely
    T? safeCast<T>(dynamic value) {
      if (value is T) return value;
      return null;
    }

    return OrderModel(
      id: json['id'] as String? ?? '', // Handle potential null ID (though Firestore IDs aren't null)
      userId: json['userId'] as String? ?? '', // Handle potential missing userId
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList() ?? [], // Handle potential missing items or non-list
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0, // Handle potential missing totalAmount or non-num
      orderTime: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), // Handle potential missing createdAt
      status: json['status'] as String? ?? 'Unknown', // Handle potential missing status
      shippingAddress: json['shippingAddress'] as String?,
      deliveredAt: (json['deliveredAt'] as Timestamp?)?.toDate(), // Handle potential missing deliveredAt
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderTime': Timestamp.fromDate(orderTime),
      'status': status,
      'shippingAddress': shippingAddress,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalAmount,
    DateTime? orderTime,
    String? status,
    String? shippingAddress,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      orderTime: orderTime ?? this.orderTime,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
} 