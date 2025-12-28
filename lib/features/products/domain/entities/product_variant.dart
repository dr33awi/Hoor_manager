/// نوع القسم (أطفال أو نسائي)
enum ProductSection {
  women('نسائي', 'women'),
  kids('أطفال', 'kids');

  final String arabicName;
  final String value;
  const ProductSection(this.arabicName, this.value);

  static ProductSection fromString(String value) {
    return ProductSection.values.firstWhere(
      (e) => e.value == value || e.arabicName == value,
      orElse: () => ProductSection.women,
    );
  }
}

/// متغير المنتج - يمثل تركيبة لون + مقاس مع الكمية
class ProductVariant {
  final String id;
  final String color;
  final String colorCode; // كود اللون للعرض (hex)
  final String size;
  final int quantity;
  final String? sku; // رمز المنتج الفريد
  final String? barcode;

  const ProductVariant({
    required this.id,
    required this.color,
    this.colorCode = '#000000',
    required this.size,
    required this.quantity,
    this.sku,
    this.barcode,
  });

  /// هل المخزون منخفض (أقل من 5)
  bool get isLowStock => quantity > 0 && quantity <= 5;

  /// هل نفد المخزون
  bool get isOutOfStock => quantity <= 0;

  /// هل متوفر
  bool get isAvailable => quantity > 0;

  ProductVariant copyWith({
    String? id,
    String? color,
    String? colorCode,
    String? size,
    int? quantity,
    String? sku,
    String? barcode,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      color: color ?? this.color,
      colorCode: colorCode ?? this.colorCode,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
    );
  }

  /// تحديث الكمية
  ProductVariant updateQuantity(int newQuantity) {
    return copyWith(quantity: newQuantity);
  }

  /// إضافة للمخزون
  ProductVariant addStock(int amount) {
    return copyWith(quantity: quantity + amount);
  }

  /// خصم من المخزون
  ProductVariant deductStock(int amount) {
    final newQuantity = quantity - amount;
    return copyWith(quantity: newQuantity < 0 ? 0 : newQuantity);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductVariant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProductVariant(color: $color, size: $size, qty: $quantity)';
}

/// ألوان شائعة للأحذية
class CommonColors {
  static const Map<String, String> colors = {
    'أسود': '#000000',
    'أبيض': '#FFFFFF',
    'بني': '#8B4513',
    'بيج': '#F5F5DC',
    'رمادي': '#808080',
    'أزرق': '#0000FF',
    'أزرق داكن': '#00008B',
    'أحمر': '#FF0000',
    'وردي': '#FFC0CB',
    'ذهبي': '#FFD700',
    'فضي': '#C0C0C0',
    'برتقالي': '#FFA500',
    'أخضر': '#008000',
    'بنفسجي': '#800080',
    'عنابي': '#800020',
    'كحلي': '#000080',
    'زيتي': '#808000',
    'كريمي': '#FFFDD0',
    'نحاسي': '#B87333',
    'متعدد': '#GRADIENT',
  };

  static String getColorCode(String colorName) {
    return colors[colorName] ?? '#000000';
  }

  static List<String> get colorNames => colors.keys.toList();
}

/// مقاسات الأحذية حسب القسم
class SectionSizes {
  /// مقاسات نسائية
  static const List<String> womenSizes = [
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42'
  ];

  /// مقاسات أطفال
  static const List<String> kidsSizes = [
    '20',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
    '32',
    '33',
    '34'
  ];

  /// الحصول على المقاسات حسب القسم
  static List<String> getSizesForSection(ProductSection section) {
    switch (section) {
      case ProductSection.women:
        return womenSizes;
      case ProductSection.kids:
        return kidsSizes;
    }
  }

  /// جميع المقاسات
  static List<String> get allSizes => [...kidsSizes, ...womenSizes];
}

// للتوافق مع الكود القديم
class CommonSizes {
  static List<String> get womenSizes => SectionSizes.womenSizes;
  static List<String> get kidsSizes => SectionSizes.kidsSizes;
  static List<String> get allSizes => SectionSizes.allSizes;
}
