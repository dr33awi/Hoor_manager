import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';
import 'product_variant_model.dart';

/// نموذج المنتج للتعامل مع Firestore
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.description,
    super.imageUrl,
    super.images,
    required super.categoryId,
    super.categoryName,
    required super.price,
    required super.cost,
    super.barcode,
    super.variants,
    super.isActive,
    super.lowStockThreshold,
    required super.createdAt,
    super.updatedAt,
    super.createdBy,
  });

  /// إنشاء من Map
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    final variantsList = (map['variants'] as List<dynamic>?)
            ?.map((v) => ProductVariantModel.fromMap(v as Map<String, dynamic>))
            .toList() ??
        [];

    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      images: List<String>.from(map['images'] ?? []),
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'],
      price: (map['price'] ?? 0).toDouble(),
      cost: (map['cost'] ?? 0).toDouble(),
      barcode: map['barcode'],
      variants: variantsList,
      isActive: map['isActive'] ?? true,
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: map['createdBy'],
    );
  }

  /// إنشاء من DocumentSnapshot
  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// إنشاء من Entity
  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      imageUrl: entity.imageUrl,
      images: entity.images,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      price: entity.price,
      cost: entity.cost,
      barcode: entity.barcode,
      variants: entity.variants
          .map((v) => ProductVariantModel.fromEntity(v))
          .toList(),
      isActive: entity.isActive,
      lowStockThreshold: entity.lowStockThreshold,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'images': images,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'price': price,
      'cost': cost,
      'barcode': barcode,
      'variants': variants
          .map((v) => ProductVariantModel.fromEntity(v).toMap())
          .toList(),
      'isActive': isActive,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      // حقول للبحث والفلترة
      'totalStock': totalStock,
      'isLowStock': isLowStock,
      'isOutOfStock': isOutOfStock,
    };
  }

  /// تحويل إلى Map للتحديث
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'images': images,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'price': price,
      'cost': cost,
      'barcode': barcode,
      'variants': variants
          .map((v) => ProductVariantModel.fromEntity(v).toMap())
          .toList(),
      'isActive': isActive,
      'lowStockThreshold': lowStockThreshold,
      'updatedAt': FieldValue.serverTimestamp(),
      'totalStock': totalStock,
      'isLowStock': isLowStock,
      'isOutOfStock': isOutOfStock,
    };
  }

  @override
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? images,
    String? categoryId,
    String? categoryName,
    double? price,
    double? cost,
    String? barcode,
    List<ProductVariant>? variants,
    bool? isActive,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      barcode: barcode ?? this.barcode,
      variants: variants ?? this.variants,
      isActive: isActive ?? this.isActive,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
