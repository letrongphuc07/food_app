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
      foodId: json['foodId'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      quantity: json['quantity'] as int,
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
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      orderTime: (json['orderTime'] as Timestamp).toDate(),
      status: json['status'] as String,
      shippingAddress: json['shippingAddress'] as String?,
      deliveredAt: json['deliveredAt'] != null ? (json['deliveredAt'] as Timestamp).toDate() : null,
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