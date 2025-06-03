import 'package:cloud_firestore/cloud_firestore.dart'; // Import Timestamp

class FoodModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic>? nutritionInfo;
  final List<String>? ingredients;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
    required this.rating,
    required this.reviewCount,
    this.nutritionInfo,
    this.ingredients,
    required this.createdAt,
    this.updatedAt,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
     DateTime parseDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.parse(date);
      } else if (date is DateTime) {
        return date;
      }
      return DateTime.now(); // Fallback
    }

    return FoodModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // Handle potential null or non-num
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true, // Handle potential null
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0, // Handle potential null or non-num
      reviewCount: json['reviewCount'] as int? ?? 0, // Handle potential null
      nutritionInfo: json['nutritionInfo'] as Map<String, dynamic>?,
      ingredients: (json['ingredients'] as List<dynamic>?)?.cast<String>(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'nutritionInfo': nutritionInfo,
      'ingredients': ingredients,
      'createdAt': Timestamp.fromDate(createdAt), // Use Timestamp
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null, // Use Timestamp
    };
  }

  FoodModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? nutritionInfo,
    List<String>? ingredients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 