/// نوع الخصم
enum DiscountType {
  /// نسبة مئوية
  percentage('percentage', 'نسبة مئوية'),
  
  /// قيمة ثابتة
  fixed('fixed', 'قيمة ثابتة');

  final String value;
  final String arabicName;

  const DiscountType(this.value, this.arabicName);

  static DiscountType fromString(String? value) {
    return DiscountType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DiscountType.fixed,
    );
  }
}

/// كيان الخصم
class Discount {
  final DiscountType type;
  final double value;
  final String? reason;

  const Discount({
    required this.type,
    required this.value,
    this.reason,
  });

  /// حساب قيمة الخصم
  double calculate(double subtotal) {
    if (type == DiscountType.percentage) {
      return (subtotal * value) / 100;
    }
    return value;
  }

  /// لا يوجد خصم
  static const Discount none = Discount(
    type: DiscountType.fixed,
    value: 0,
  );

  /// هل يوجد خصم
  bool get hasDiscount => value > 0;

  /// وصف الخصم
  String get description {
    if (!hasDiscount) return 'لا يوجد خصم';
    if (type == DiscountType.percentage) {
      return '$value%';
    }
    return '$value ر.ي';
  }

  Discount copyWith({
    DiscountType? type,
    double? value,
    String? reason,
  }) {
    return Discount(
      type: type ?? this.type,
      value: value ?? this.value,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'value': value,
      'reason': reason,
    };
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      type: DiscountType.fromString(map['type']),
      value: (map['value'] ?? 0).toDouble(),
      reason: map['reason'],
    );
  }

  @override
  String toString() => 'Discount(type: ${type.arabicName}, value: $value)';
}
