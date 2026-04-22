import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus { pending, approved, rejected, cancelled }

class PaymentDetails {
  PaymentDetails({
    this.cardBrand,
    this.lastFourDigits,
  });

  final String? cardBrand;
  final String? lastFourDigits;

  factory PaymentDetails.fromMap(Map<String, dynamic>? data) {
    if (data == null) return PaymentDetails();
    return PaymentDetails(
      cardBrand: data['cardBrand'] as String?,
      lastFourDigits: data['lastFourDigits'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (cardBrand != null) 'cardBrand': cardBrand,
      if (lastFourDigits != null) 'lastFourDigits': lastFourDigits,
    };
  }
}

class TransactionModel {
  TransactionModel({
    required this.id,
    required this.mercadoPagoId,
    required this.preferenceId,
    required this.plan,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.paymentDetails,
    required this.externalReference,
    required this.createdAt,
    this.processedAt,
    this.approvedAt,
    this.metadata,
  });

  final String id;
  final String mercadoPagoId;
  final String preferenceId;
  final String plan;
  final double amount;
  final TransactionStatus status;
  final String paymentMethod;
  final PaymentDetails? paymentDetails;
  final String externalReference;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? approvedAt;
  final Map<String, dynamic>? metadata;

  factory TransactionModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return TransactionModel(
      id: doc.id,
      mercadoPagoId: (data['mercadoPagoId'] ?? '') as String,
      preferenceId: (data['preferenceId'] ?? '') as String,
      plan: (data['plan'] ?? '') as String,
      amount: ((data['amount'] ?? 0) as num).toDouble(),
      status: _parseStatus(data['status']),
      paymentMethod: (data['paymentMethod'] ?? '') as String,
      paymentDetails: PaymentDetails.fromMap(
        data['paymentDetails'] as Map<String, dynamic>?,
      ),
      externalReference: (data['externalReference'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  static TransactionStatus _parseStatus(dynamic value) {
    if (value == null) return TransactionStatus.pending;
    switch (value.toString()) {
      case 'approved':
        return TransactionStatus.approved;
      case 'rejected':
        return TransactionStatus.rejected;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'mercadoPagoId': mercadoPagoId,
      'preferenceId': preferenceId,
      'plan': plan,
      'amount': amount,
      'status': status.name,
      'paymentMethod': paymentMethod,
      if (paymentDetails != null) 'paymentDetails': paymentDetails!.toMap(),
      'externalReference': externalReference,
      'createdAt': Timestamp.fromDate(createdAt),
      if (processedAt != null) 'processedAt': Timestamp.fromDate(processedAt!),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (metadata != null) 'metadata': metadata,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? mercadoPagoId,
    String? preferenceId,
    String? plan,
    double? amount,
    TransactionStatus? status,
    String? paymentMethod,
    PaymentDetails? paymentDetails,
    String? externalReference,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? approvedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      mercadoPagoId: mercadoPagoId ?? this.mercadoPagoId,
      preferenceId: preferenceId ?? this.preferenceId,
      plan: plan ?? this.plan,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      externalReference: externalReference ?? this.externalReference,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Verifica se a transação foi aprovada
  bool get isApproved => status == TransactionStatus.approved;

  /// Verifica se a transação está pendente
  bool get isPending => status == TransactionStatus.pending;

  /// Verifica se a transação foi rejeitada
  bool get isRejected => status == TransactionStatus.rejected;

  /// Verifica se a transação foi cancelada
  bool get isCancelled => status == TransactionStatus.cancelled;
}
