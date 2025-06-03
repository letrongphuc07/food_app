import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/food_model.dart'; // Import FoodModel
import 'package:cached_network_image/cached_network_image.dart'; // For loading images
import 'cart_screen.dart'; // Import CartScreen
import 'package:provider/provider.dart'; // Import Provider
import '../providers/cart_provider.dart'; // Import CartProvider
import 'notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedCategory; // Add state for selected category
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _configureFCM();
  }

  Future<void> _configureFCM() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // Get the initial token and save it
      String? token = await _firebaseMessaging.getToken();
      if (token != null && _auth.currentUser != null) {
        await _saveTokenToFirestore(token);
      }

      // Listen for token changes and save them
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (_auth.currentUser != null) {
           _saveTokenToFirestore(newToken);
        }
      });

      // Handle messages when the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          // You might want to show a local notification here
        }
      });

      // Handle messages when the app is in the background or terminated
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    if (_auth.currentUser != null) {
      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
          'fcmToken': token,
          'lastLoginAt': FieldValue.serverTimestamp(), // Update last login as well
        }, SetOptions(merge: true)); // Use merge: true to avoid overwriting other user data
        print('FCM token saved for user: ${_auth.currentUser!.uid}');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    }
  }

  // Top-level function to handle background messages
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // If you're using other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using them.
    // await Firebase.initializeApp(); // Uncomment if needed

    print("Handling a background message: ${message.messageId}");
    // You can perform background tasks here, e.g., update UI, save data
  }

  @override
  void dispose() {
    // Consider disposing listeners if necessary, although onTokenRefresh listener
    // is typically long-lived and managed by the plugin.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng dụng đặt đồ ăn'),
        actions: [
          // User Profile Button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          // Cart Button
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ));
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartProvider.itemCount.toString(),
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
          final categories = ['Tất cả'] + allFoods.map((food) => food.category).toSet().toList();

          // Apply category filter if a category is selected
          final filteredFoods = _selectedCategory == null || _selectedCategory == 'Tất cả'
              ? allFoods
              : allFoods.where((food) => food.category == _selectedCategory).toList();

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
              
              // Food List
              Text(
                'Danh sách món ăn', // Changed title from Popular Items
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
                itemCount: filteredFoods.length, // Use the count of filteredFoods
                itemBuilder: (context, index) {
                  final food = filteredFoods[index]; // Use filteredFoods here
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
                      '${food.price.toStringAsFixed(0)}₫', // Changed from $ to ₫ and removed .00
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