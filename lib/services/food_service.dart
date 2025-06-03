import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_model.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'foods';

  // Get all foods
  Stream<List<FoodModel>> getFoods() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FoodModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  // Get foods by category
  Stream<List<FoodModel>> getFoodsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FoodModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  // Get food by ID
  Future<FoodModel> getFoodById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists) {
        throw Exception('Food not found');
      }

      return FoodModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to get food: $e');
    }
  }

  // Add new food
  Future<FoodModel> addFood(FoodModel food) async {
    try {
      final DocumentReference docRef = await _firestore.collection(_collection).add(food.toJson());
      return food.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to add food: $e');
    }
  }

  // Update food
  Future<void> updateFood(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update food: $e');
    }
  }

  // Delete food
  Future<void> deleteFood(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete food: $e');
    }
  }

  // Search foods
  Stream<List<FoodModel>> searchFoods(String query) {
    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FoodModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  // Get popular foods
  Stream<List<FoodModel>> getPopularFoods() {
    return _firestore
        .collection(_collection)
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FoodModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    });
  }

  // Update food rating
  Future<void> updateFoodRating(String id, double rating, int reviewCount) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'rating': rating,
        'reviewCount': reviewCount,
      });
    } catch (e) {
      throw Exception('Failed to update food rating: $e');
    }
  }
} 