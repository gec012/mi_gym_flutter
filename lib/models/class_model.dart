import 'package:mi_gym_flutter/models/category_model.dart';

class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? categoryId;
  final String intensity;
  final int durationMinutes;
  final int capacity;
  final double basePrice;
  final CategoryModel? category;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.intensity = 'Medium',
    required this.durationMinutes,
    this.capacity = 20,
    this.basePrice = 0.0,
    this.category,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String?,
      intensity: json['intensity'] as String? ?? 'Medium',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      capacity: (json['capacity'] as num?)?.toInt() ?? 20,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      category: json['categories'] != null
          ? CategoryModel.fromJson(json['categories'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category_id': categoryId,
      'intensity': intensity,
      'duration_minutes': durationMinutes,
      'capacity': capacity,
      'base_price': basePrice,
    };
  }
}
