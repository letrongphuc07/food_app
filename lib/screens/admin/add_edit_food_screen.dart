import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/food_model.dart'; // Import FoodModel

class AddEditFoodScreen extends StatefulWidget {
  final FoodModel? food; // Optional FoodModel for editing

  const AddEditFoodScreen({super.key, this.food});

  @override
  State<AddEditFoodScreen> createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends State<AddEditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  // You might need more controllers for other fields like isAvailable, etc.

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // If editing, populate the form fields
    if (widget.food != null) {
      _nameController.text = widget.food!.name;
      _descriptionController.text = widget.food!.description;
      _priceController.text = widget.food!.price.toString();
      _imageUrlController.text = widget.food!.imageUrl;
      _categoryController.text = widget.food!.category;
      // Populate other fields if added
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _saveFood() async {
    if (_formKey.currentState!.validate()) {
      // Process data
      final foodData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text), // Convert price to double
        'imageUrl': _imageUrlController.text,
        'category': _categoryController.text,
        'isAvailable': widget.food?.isAvailable ?? true, // Keep existing or default
        'rating': widget.food?.rating ?? 0.0, // Keep existing or default
        'reviewCount': widget.food?.reviewCount ?? 0, // Keep existing or default
        // Add other fields as necessary
      };

      try {
        if (widget.food == null) {
          // Add new food
           foodData['createdAt'] = FieldValue.serverTimestamp();
           foodData['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('foods').add(foodData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Món ăn đã được thêm!')), // Translated success message
          );
        } else {
          // Update existing food
          foodData['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('foods').doc(widget.food!.id).update(foodData);
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Món ăn đã được cập nhật!')), // Translated success message
          );
        }
        
        Navigator.of(context).pop(); // Go back after saving
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu món ăn: $e')), // Translated error message
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.food != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa món ăn' : 'Thêm món ăn mới'), // Translated title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên món ăn'), // Translated label
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên món ăn'; // Translated validation message
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'), // Translated label
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả món ăn'; // Translated validation message
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá'), // Translated label
                keyboardType: TextInputType.number, // Allow only numbers
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá'; // Translated validation message
                  }
                  if (double.tryParse(value) == null) {
                     return 'Vui lòng nhập số hợp lệ'; // Translated validation message
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'), // Translated label
                keyboardType: TextInputType.url,
                // imageUrl can be optional, so no validator needed unless required
              ),
               TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Danh mục'), // Translated label
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập danh mục'; // Translated validation message
                  }
                  return null;
                },
              ),
              // Add other form fields for isAvailable, nutritionInfo, ingredients, etc.

              const SizedBox(height: 24.0),

              ElevatedButton(
                onPressed: _saveFood,
                child: Text(isEditing ? 'Cập nhật món ăn' : 'Lưu món ăn'), // Translated button text
              ),
            ],
          ),
        ),
      ),
    );
  }
} 