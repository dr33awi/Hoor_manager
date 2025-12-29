import 'package:drift/drift.dart';
import '../../data/database/app_database.dart' as db;

/// ═══════════════════════════════════════════════════════════════════════════
/// Entity Mappers - توحيد منطق التحويل بين Models و Maps
/// ═══════════════════════════════════════════════════════════════════════════

/// Interface أساسي لجميع الـ Mappers
abstract class EntityMapper<T, C> {
  Map<String, dynamic> toMap(T entity);
  C fromMap(Map<String, dynamic> data);
  Map<String, dynamic> toFirestore(T entity);
  C fromFirestore(Map<String, dynamic> data, String id);
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Product Mapper
/// ═══════════════════════════════════════════════════════════════════════════
class ProductMapper implements EntityMapper<db.Product, db.ProductsCompanion> {
  const ProductMapper();

  @override
  Map<String, dynamic> toMap(db.Product p) => {
        'id': p.id,
        'name': p.name,
        'sku': p.sku,
        'barcode': p.barcode,
        'categoryId': p.categoryId,
        'purchasePrice': p.purchasePrice,
        'salePrice': p.salePrice,
        'quantity': p.quantity,
        'minQuantity': p.minQuantity,
        'taxRate': p.taxRate,
        'description': p.description,
        'imageUrl': p.imageUrl,
        'isActive': p.isActive,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
      };

  @override
  db.ProductsCompanion fromMap(Map<String, dynamic> data) {
    return db.ProductsCompanion(
      id: Value(data['id'] as String),
      name: Value(data['name'] as String),
      sku: Value(data['sku'] as String?),
      barcode: Value(data['barcode'] as String?),
      categoryId: Value(data['categoryId'] as String?),
      purchasePrice: Value((data['purchasePrice'] as num).toDouble()),
      salePrice: Value((data['salePrice'] as num).toDouble()),
      quantity: Value(data['quantity'] as int),
      minQuantity: Value(data['minQuantity'] as int),
      taxRate: Value((data['taxRate'] as num?)?.toDouble() ?? 0),
      description: Value(data['description'] as String?),
      imageUrl: Value(data['imageUrl'] as String?),
      isActive: Value(data['isActive'] as bool? ?? true),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  @override
  Map<String, dynamic> toFirestore(db.Product p) => toMap(p);

  @override
  db.ProductsCompanion fromFirestore(Map<String, dynamic> data, String id) {
    data['id'] = id;
    return fromMap(data);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Category Mapper
/// ═══════════════════════════════════════════════════════════════════════════
class CategoryMapper
    implements EntityMapper<db.Category, db.CategoriesCompanion> {
  const CategoryMapper();

  @override
  Map<String, dynamic> toMap(db.Category c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'parentId': c.parentId,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
      };

  @override
  db.CategoriesCompanion fromMap(Map<String, dynamic> data) {
    return db.CategoriesCompanion(
      id: Value(data['id'] as String),
      name: Value(data['name'] as String),
      description: Value(data['description'] as String?),
      parentId: Value(data['parentId'] as String?),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  @override
  Map<String, dynamic> toFirestore(db.Category c) => toMap(c);

  @override
  db.CategoriesCompanion fromFirestore(Map<String, dynamic> data, String id) {
    data['id'] = id;
    return fromMap(data);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Customer Mapper
/// ═══════════════════════════════════════════════════════════════════════════
class CustomerMapper
    implements EntityMapper<db.Customer, db.CustomersCompanion> {
  const CustomerMapper();

  @override
  Map<String, dynamic> toMap(db.Customer c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'email': c.email,
        'address': c.address,
        'balance': c.balance,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
      };

  @override
  db.CustomersCompanion fromMap(Map<String, dynamic> data) {
    return db.CustomersCompanion(
      id: Value(data['id'] as String),
      name: Value(data['name'] as String),
      phone: Value(data['phone'] as String?),
      email: Value(data['email'] as String?),
      address: Value(data['address'] as String?),
      balance: Value((data['balance'] as num?)?.toDouble() ?? 0),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  @override
  Map<String, dynamic> toFirestore(db.Customer c) => toMap(c);

  @override
  db.CustomersCompanion fromFirestore(Map<String, dynamic> data, String id) {
    data['id'] = id;
    return fromMap(data);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Supplier Mapper
/// ═══════════════════════════════════════════════════════════════════════════
class SupplierMapper
    implements EntityMapper<db.Supplier, db.SuppliersCompanion> {
  const SupplierMapper();

  @override
  Map<String, dynamic> toMap(db.Supplier s) => {
        'id': s.id,
        'name': s.name,
        'phone': s.phone,
        'email': s.email,
        'address': s.address,
        'balance': s.balance,
        'notes': s.notes,
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
      };

  @override
  db.SuppliersCompanion fromMap(Map<String, dynamic> data) {
    return db.SuppliersCompanion(
      id: Value(data['id'] as String),
      name: Value(data['name'] as String),
      phone: Value(data['phone'] as String?),
      email: Value(data['email'] as String?),
      address: Value(data['address'] as String?),
      balance: Value((data['balance'] as num?)?.toDouble() ?? 0),
      notes: Value(data['notes'] as String?),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  @override
  Map<String, dynamic> toFirestore(db.Supplier s) => toMap(s);

  @override
  db.SuppliersCompanion fromFirestore(Map<String, dynamic> data, String id) {
    data['id'] = id;
    return fromMap(data);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Invoice Mapper
/// ═══════════════════════════════════════════════════════════════════════════
class InvoiceMapper implements EntityMapper<db.Invoice, db.InvoicesCompanion> {
  const InvoiceMapper();

  @override
  Map<String, dynamic> toMap(db.Invoice i) => {
        'id': i.id,
        'invoiceNumber': i.invoiceNumber,
        'type': i.type,
        'customerId': i.customerId,
        'supplierId': i.supplierId,
        'subtotal': i.subtotal,
        'taxAmount': i.taxAmount,
        'discountAmount': i.discountAmount,
        'total': i.total,
        'paymentMethod': i.paymentMethod,
        'paidAmount': i.paidAmount,
        'status': i.status,
        'notes': i.notes,
        'shiftId': i.shiftId,
        'invoiceDate': i.invoiceDate.toIso8601String(),
        'createdAt': i.createdAt.toIso8601String(),
        'updatedAt': i.updatedAt.toIso8601String(),
      };

  @override
  db.InvoicesCompanion fromMap(Map<String, dynamic> data) {
    return db.InvoicesCompanion(
      id: Value(data['id'] as String),
      invoiceNumber: Value(data['invoiceNumber'] as String),
      type: Value(data['type'] as String),
      customerId: Value(data['customerId'] as String?),
      supplierId: Value(data['supplierId'] as String?),
      subtotal: Value((data['subtotal'] as num).toDouble()),
      taxAmount: Value((data['taxAmount'] as num?)?.toDouble() ?? 0),
      discountAmount: Value((data['discountAmount'] as num?)?.toDouble() ?? 0),
      total: Value((data['total'] as num).toDouble()),
      paymentMethod: Value(data['paymentMethod'] as String),
      paidAmount: Value((data['paidAmount'] as num?)?.toDouble() ?? 0),
      status: Value(data['status'] as String? ?? 'completed'),
      notes: Value(data['notes'] as String?),
      shiftId: Value(data['shiftId'] as String?),
      invoiceDate: Value(DateTime.parse(data['invoiceDate'] as String)),
      createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
    );
  }

  @override
  Map<String, dynamic> toFirestore(db.Invoice i) => toMap(i);

  @override
  db.InvoicesCompanion fromFirestore(Map<String, dynamic> data, String id) {
    data['id'] = id;
    return fromMap(data);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Mappers Registry - مركز موحد للوصول لجميع الـ Mappers
/// ═══════════════════════════════════════════════════════════════════════════
class Mappers {
  Mappers._();

  static const product = ProductMapper();
  static const category = CategoryMapper();
  static const customer = CustomerMapper();
  static const supplier = SupplierMapper();
  static const invoice = InvoiceMapper();
}
