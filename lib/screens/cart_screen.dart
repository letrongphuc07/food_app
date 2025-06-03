import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  void _placeOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<CartProvider>(context, listen: false).placeOrder(null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn'),
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text('Giỏ hàng trống.'),
            )
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartItems.values.toList()[index];
                return ListTile(
                  leading: cartItem.imageUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(cartItem.imageUrl),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.fastfood),
                        ),
                  title: Text(cartItem.name),
                  subtitle: Text('Giá: \$${cartItem.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          cartProvider.removeSingleItem(cartItem.id);
                        },
                      ),
                      Text(cartItem.quantity.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          cartProvider.updateQuantity(cartItem.id, cartItem.quantity + 1);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng cộng: \$${cartProvider.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _placeOrder,
                          child: const Text('Đặt hàng ngay'),
                        ),
                ],
              ),
            ),
    );
  }
} 