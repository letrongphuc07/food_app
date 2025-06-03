import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  String? specialInstructions;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.specialInstructions,
  });

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  String? _shippingAddress;
  String? _deliveryNote;

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  int get totalItems {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  String? get shippingAddress => _shippingAddress;
  String? get deliveryNote => _deliveryNote;
  bool get isEmpty => _items.isEmpty;

  void addItem(FoodModel food, int quantity) {
    if (_items.containsKey(food.id)) {
      _items.update(
        food.id,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          quantity: existingCartItem.quantity + quantity,
          specialInstructions: existingCartItem.specialInstructions,
        ),
      );
    } else {
      _items.putIfAbsent(
        food.id,
        () => CartItem(
          id: food.id,
          name: food.name,
          price: food.price,
          imageUrl: food.imageUrl,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String foodId) {
    _items.remove(foodId);
    notifyListeners();
  }

  void removeSingleItem(String foodId) {
    if (!_items.containsKey(foodId)) {
      return;
    }
    if (_items[foodId]!.quantity > 1) {
      _items.update(
        foodId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
          quantity: existingCartItem.quantity - 1,
          specialInstructions: existingCartItem.specialInstructions,
        ),
      );
    } else {
      _items.remove(foodId);
    }
    notifyListeners();
  }

  void updateQuantity(String foodId, int quantity) {
    if (_items.containsKey(foodId)) {
      if (quantity <= 0) {
        _items.remove(foodId);
      } else {
        _items.update(
          foodId,
          (existingCartItem) => existingCartItem.copyWith(quantity: quantity),
        );
      }
      notifyListeners();
    }
  }

  void updateSpecialInstructions(String foodId, String? specialInstructions) {
    if (_items.containsKey(foodId)) {
      _items.update(
        foodId,
        (existingCartItem) => existingCartItem.copyWith(specialInstructions: specialInstructions),
      );
      notifyListeners();
    }
  }

  void setShippingAddress(String address) {
    _shippingAddress = address;
    notifyListeners();
  }

  void setDeliveryNote(String note) {
    _deliveryNote = note;
    notifyListeners();
  }

  void clear() {
    _items = {};
    _shippingAddress = null;
    _deliveryNote = null;
    notifyListeners();
  }

  Future<void> placeOrder(String? shippingAddress) async {
    if (_items.isEmpty) {
      throw Exception('Giỏ hàng trống!');
    }

    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập!');
    }

    final orderItems = _items.values.map((cartItem) => OrderItem(
      foodId: cartItem.id,
      name: cartItem.name,
      price: cartItem.price,
      imageUrl: cartItem.imageUrl,
      quantity: cartItem.quantity,
    )).toList();

    final order = OrderModel(
      id: DateTime.now().toString(),
      userId: user.uid,
      items: orderItems,
      totalAmount: totalAmount,
      orderTime: DateTime.now(),
      status: 'Pending',
      shippingAddress: shippingAddress,
    );

    try {
      await _orderService.placeOrder(order);
      clear();
    } catch (e) {
      throw Exception('Đặt hàng thất bại: $e');
    }
  }
} 