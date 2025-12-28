import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// نموذج الفئة للتعامل مع Firestore
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    super.description,
    super.imageUrl,
    super.order,
    super.isActive,
    required super.createdAt,
  });

  /// إنشاء من Map
  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// إنشاء من DocumentSnapshot
  factory CategoryModel.fromDocument(DocumentSnapshot doc) {
    return CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// إنشاء من Entity
  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      imageUrl: entity.imageUrl,
      order: entity.order,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? order,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
