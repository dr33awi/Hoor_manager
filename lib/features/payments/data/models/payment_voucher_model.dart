import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

/// نموذج السند المالي للتعامل مع Firestore
class PaymentVoucherModel extends PaymentVoucherEntity {
  const PaymentVoucherModel({
    required super.id,
    required super.voucherNumber,
    required super.type,
    super.status,
    required super.paymentMethod,
    required super.date,
    required super.amount,
    super.customerId,
    super.customerName,
    super.supplierId,
    super.supplierName,
    super.accountId,
    super.accountName,
    super.invoiceId,
    super.invoiceNumber,
    super.purchaseId,
    super.purchaseNumber,
    super.chequeNumber,
    super.chequeDate,
    super.bankName,
    super.bankAccount,
    super.transferReference,
    super.description,
    super.notes,
    super.attachments,
    required super.createdAt,
    super.updatedAt,
    super.createdBy,
    super.approvedBy,
    super.approvedAt,
  });

  factory PaymentVoucherModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentVoucherModel(
      id: id,
      voucherNumber: map['voucherNumber'] ?? '',
      type: PaymentVoucherType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentVoucherType.receipt,
      ),
      status: PaymentVoucherStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentVoucherStatus.draft,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      date: _parseDateTime(map['date']) ?? DateTime.now(),
      amount: (map['amount'] ?? 0).toDouble(),
      customerId: map['customerId'],
      customerName: map['customerName'],
      supplierId: map['supplierId'],
      supplierName: map['supplierName'],
      accountId: map['accountId'],
      accountName: map['accountName'],
      invoiceId: map['invoiceId'],
      invoiceNumber: map['invoiceNumber'],
      purchaseId: map['purchaseId'],
      purchaseNumber: map['purchaseNumber'],
      chequeNumber: map['chequeNumber'],
      chequeDate: map['chequeDate'],
      bankName: map['bankName'],
      bankAccount: map['bankAccount'],
      transferReference: map['transferReference'],
      description: map['description'],
      notes: map['notes'],
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']),
      createdBy: map['createdBy'],
      approvedBy: map['approvedBy'],
      approvedAt: _parseDateTime(map['approvedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory PaymentVoucherModel.fromDocument(DocumentSnapshot doc) {
    return PaymentVoucherModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  factory PaymentVoucherModel.fromEntity(PaymentVoucherEntity entity) {
    return PaymentVoucherModel(
      id: entity.id,
      voucherNumber: entity.voucherNumber,
      type: entity.type,
      status: entity.status,
      paymentMethod: entity.paymentMethod,
      date: entity.date,
      amount: entity.amount,
      customerId: entity.customerId,
      customerName: entity.customerName,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      accountId: entity.accountId,
      accountName: entity.accountName,
      invoiceId: entity.invoiceId,
      invoiceNumber: entity.invoiceNumber,
      purchaseId: entity.purchaseId,
      purchaseNumber: entity.purchaseNumber,
      chequeNumber: entity.chequeNumber,
      chequeDate: entity.chequeDate,
      bankName: entity.bankName,
      bankAccount: entity.bankAccount,
      transferReference: entity.transferReference,
      description: entity.description,
      notes: entity.notes,
      attachments: entity.attachments,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voucherNumber': voucherNumber,
      'type': type.name,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'customerId': customerId,
      'customerName': customerName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'accountId': accountId,
      'accountName': accountName,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'purchaseId': purchaseId,
      'purchaseNumber': purchaseNumber,
      'chequeNumber': chequeNumber,
      'chequeDate': chequeDate,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'transferReference': transferReference,
      'description': description,
      'notes': notes,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }
}
