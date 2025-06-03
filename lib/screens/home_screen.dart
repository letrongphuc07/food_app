import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/food_model.dart'; // Import FoodModel
import 'package:cached_network_image/cached_network_image.dart'; // For loading images
import 'cart_screen.dart'; // Import CartScreen
import 'package:provider/provider.dart'; // Import Provider
import '../providers/cart_provider.dart'; // Import CartProvider

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedCategory; // Add state for selected category

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng dụng đặt đồ ăn'),
        actions: [
          Consumer<CartProvider>( // Use Consumer to listen to cart changes
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      // Navigate to cart screen
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ));
                    },
                  ),
                  if (cartProvider.itemCount > 0) // Show badge if cart is not empty
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red, // Badge color
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartProvider.itemCount.toString(), // Item count
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('foods').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có món ăn nào.'));
          }

          final allFoods = snapshot.data!.docs.map((doc) {
            return FoodModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            });
          }).toList();

          // Extract unique categories and add 'Tất cả' option
          final categories = ['Tất cả'] + allFoods.map((food) => food.category).toSet().toList(); // Add 'Tất cả'

          // Filter popular items (example: top rated or fixed number)
          // Apply category filter if a category is selected
          final filteredFoods = _selectedCategory == null || _selectedCategory == 'Tất cả'
              ? allFoods
              : allFoods.where((food) => food.category == _selectedCategory).toList();

          // For simplicity, let's just take the first few from filteredFoods for now
          final popularItems = filteredFoods.take(4).toList(); 

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm món ăn...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Categories
              Text(
                'Danh mục',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                height: 120,
                child: ListView.builder(
                   scrollDirection: Axis.horizontal,
                   itemCount: categories.length,
                   itemBuilder: (context, index) {
                     final category = categories[index];
                     // You might want to store icons per category or use a default
                     IconData categoryIcon = Icons.category; // Default icon
                     // Add logic to select icon based on category name if needed
                     return GestureDetector( // Make the card tappable
                       onTap: () {
                         setState(() {
                           _selectedCategory = category == 'Tất cả' ? null : category;
                         });
                       },
                       child: _buildCategoryCard(category, categoryIcon, _selectedCategory == category || (_selectedCategory == null && category == 'Tất cả')), // Pass selection state
                     );
                   }
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Popular Items
              Text(
                'Món ăn phổ biến',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: popularItems.length,
                itemBuilder: (context, index) {
                  final food = popularItems[index];
                  return _buildFoodCard(food);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, bool isSelected) {
    return Card(
      color: isSelected ? Theme.of(context).primaryColor : null, // Change color if selected
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : null), // Change icon color
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : null, // Change text color
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodModel food) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: food.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: food.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.fastfood, size: 48),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  food.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Arrange price and button
                  children: [
                    Text(
                      '\$${food.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Theme.of(context).primaryColor, // Button color
                      onPressed: () {
                        // Add item to cart
                        Provider.of<CartProvider>(context, listen: false).addItem(food, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm ${food.name} vào giỏ hàng!')),
                        ); // Show confirmation
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 