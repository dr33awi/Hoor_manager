import 'package:hive_flutter/hive_flutter.dart';

import '../../../features/products/domain/entities/product_entity.dart';
import '../../../features/products/domain/entities/product_variant.dart';
import '../../../features/products/domain/entities/category_entity.dart';

// ==================== Type IDs ====================
// تأكد من أن كل Type ID فريد ولا يتغير أبداً
class HiveTypeIds {
  static const int productVariant = 0;
  static const int productEntity = 1;
  static const int categoryEntity = 2;
  static const int cachedProduct = 3;
}

// ==================== Product Variant Adapter ====================
class ProductVariantAdapter extends TypeAdapter<ProductVariant> {
  @override
  final int typeId = HiveTypeIds.productVariant;

  @override
  ProductVariant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductVariant(
      id: fields[0] as String,
      color: fields[1] as String,
      colorCode: fields[2] as String? ?? '#000000',
      size: fields[3] as String,
      quantity: fields[4] as int,
      sku: fields[5] as String?,
      barcode: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductVariant obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.color)
      ..writeByte(2)
      ..write(obj.colorCode)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.sku)
      ..writeByte(6)
      ..write(obj.barcode);
  }
}

// ==================== Cached Product (للتخزين المحلي) ====================
/// نسخة مخصصة للتخزين المحلي مع جميع البيانات اللازمة
class CachedProduct {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> images;
  final String categoryId;
  final String? categoryName;
  final double price;
  final double cost;
  final String? barcode;
  final List<ProductVariant> variants;
  final bool isActive;
  final int lowStockThreshold;
  final int createdAtMillis;
  final int? updatedAtMillis;
  final String? createdBy;

  CachedProduct({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.images = const [],
    required this.categoryId,
    this.categoryName,
    required this.price,
    required this.cost,
    this.barcode,
    this.variants = const [],
    this.isActive = true,
    this.lowStockThreshold = 5,
    required this.createdAtMillis,
    this.updatedAtMillis,
    this.createdBy,
  });

  /// تحويل من ProductEntity
  factory CachedProduct.fromEntity(ProductEntity entity) {
    return CachedProduct(
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
      variants: entity.variants,
      isActive: entity.isActive,
      lowStockThreshold: entity.lowStockThreshold,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: entity.updatedAt?.millisecondsSinceEpoch,
      createdBy: entity.createdBy,
    );
  }

  /// تحويل إلى ProductEntity
  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      images: images,
      categoryId: categoryId,
      categoryName: categoryName,
      price: price,
      cost: cost,
      barcode: barcode,
      variants: variants,
      isActive: isActive,
      lowStockThreshold: lowStockThreshold,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: updatedAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMillis!)
          : null,
      createdBy: createdBy,
    );
  }

  /// تحويل من Map (للتوافق مع الكود القديم)
  factory CachedProduct.fromMap(Map<String, dynamic> map) {
    final variantsList = (map['variants'] as List<dynamic>?)
            ?.map((v) => ProductVariant(
                  id: v['id'] ?? '',
                  color: v['color'] ?? '',
                  colorCode: v['colorCode'] ?? '#000000',
                  size: v['size'] ?? '',
                  quantity: v['quantity'] ?? 0,
                  sku: v['sku'],
                  barcode: v['barcode'],
                ))
            .toList() ??
        [];

    // معالجة التاريخ
    int createdAtMillis = DateTime.now().millisecondsSinceEpoch;
    final createdAt = map['createdAt'];
    if (createdAt is int) {
      createdAtMillis = createdAt;
    } else if (createdAt is Map) {
      final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
      if (seconds != null) {
        createdAtMillis = (seconds as int) * 1000;
      }
    }

    int? updatedAtMillis;
    final updatedAt = map['updatedAt'];
    if (updatedAt is int) {
      updatedAtMillis = updatedAt;
    } else if (updatedAt is Map) {
      final seconds = updatedAt['_seconds'] ?? updatedAt['seconds'];
      if (seconds != null) {
        updatedAtMillis = (seconds as int) * 1000;
      }
    }

    return CachedProduct(
      id: map['id'] ?? '',
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
      createdAtMillis: createdAtMillis,
      updatedAtMillis: updatedAtMillis,
      createdBy: map['createdBy'],
    );
  }
}

// ==================== Cached Product Adapter ====================
class CachedProductAdapter extends TypeAdapter<CachedProduct> {
  @override
  final int typeId = HiveTypeIds.cachedProduct;

  @override
  CachedProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedProduct(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      imageUrl: fields[3] as String?,
      images: (fields[4] as List?)?.cast<String>() ?? [],
      categoryId: fields[5] as String,
      categoryName: fields[6] as String?,
      price: fields[7] as double,
      cost: fields[8] as double,
      barcode: fields[9] as String?,
      variants: (fields[10] as List?)?.cast<ProductVariant>() ?? [],
      isActive: fields[11] as bool? ?? true,
      lowStockThreshold: fields[12] as int? ?? 5,
      createdAtMillis: fields[13] as int,
      updatedAtMillis: fields[14] as int?,
      createdBy: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedProduct obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.images)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.categoryName)
      ..writeByte(7)
      ..write(obj.price)
      ..writeByte(8)
      ..write(obj.cost)
      ..writeByte(9)
      ..write(obj.barcode)
      ..writeByte(10)
      ..write(obj.variants)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.lowStockThreshold)
      ..writeByte(13)
      ..write(obj.createdAtMillis)
      ..writeByte(14)
      ..write(obj.updatedAtMillis)
      ..writeByte(15)
      ..write(obj.createdBy);
  }
}

// ==================== Category Entity Adapter ====================
class CategoryEntityAdapter extends TypeAdapter<CategoryEntity> {
  @override
  final int typeId = HiveTypeIds.categoryEntity;

  @override
  CategoryEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryEntity(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      imageUrl: fields[3] as String?,
      order: fields[4] as int? ?? 0,
      isActive: fields[5] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
    );
  }

  @override
  void write(BinaryWriter writer, CategoryEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.order)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }
}

// ==================== تسجيل جميع الـ Adapters ====================
void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(HiveTypeIds.productVariant)) {
    Hive.registerAdapter(ProductVariantAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.cachedProduct)) {
    Hive.registerAdapter(CachedProductAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.categoryEntity)) {
    Hive.registerAdapter(CategoryEntityAdapter());
  }
}
