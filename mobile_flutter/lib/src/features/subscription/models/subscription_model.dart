import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan { free, monthly, quarterly, annual }

enum SubscriptionStatus { active, expired, trial }

class SubscriptionModel {
  SubscriptionModel({
    required this.plan,
    required this.status,
    required this.startDate,
    required this.expirationDate,
    required this.trialUsed,
    required this.autoRenew,
    required this.createdAt,
    required this.updatedAt,
  });

  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime expirationDate;
  final bool trialUsed;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SubscriptionModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SubscriptionModel(
      plan: _parsePlan(data['plan']),
      status: _parseStatus(data['status']),
      startDate: _parseDate(data['startDate']),
      expirationDate: _parseDate(data['expirationDate']),
      trialUsed: (data['trialUsed'] ?? false) as bool,
      autoRenew: (data['autoRenew'] ?? false) as bool,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  // Método simples: parsear string ISO 8601 (100% compatível com Flutter Web)
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    
    try {
      // Se for string ISO 8601
      if (value is String) {
        return DateTime.parse(value);
      }
      
      // Se for Timestamp do Firestore (fallback para dados antigos)
      if (value is Timestamp) {
        return value.toDate();
      }
      
      // Se for DateTime
      if (value is DateTime) {
        return value;
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    
    // Fallback
    return DateTime.now();
  }

  static SubscriptionPlan _parsePlan(dynamic value) {
    if (value == null) return SubscriptionPlan.free;
    switch (value.toString()) {
      case 'monthly':
        return SubscriptionPlan.monthly;
      case 'quarterly':
        return SubscriptionPlan.quarterly;
      case 'annual':
        return SubscriptionPlan.annual;
      case 'free':
      default:
        return SubscriptionPlan.free;
    }
  }

  static SubscriptionStatus _parseStatus(dynamic value) {
    if (value == null) return SubscriptionStatus.trial;
    switch (value.toString()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'trial':
      default:
        return SubscriptionStatus.trial;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan.name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'trialUsed': trialUsed,
      'autoRenew': autoRenew,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SubscriptionModel copyWith({
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? expirationDate,
    bool? trialUsed,
    bool? autoRenew,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      expirationDate: expirationDate ?? this.expirationDate,
      trialUsed: trialUsed ?? this.trialUsed,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se a assinatura está ativa
  bool get isActive {
    return status == SubscriptionStatus.active ||
        (status == SubscriptionStatus.trial &&
            expirationDate.isAfter(DateTime.now()));
  }

  /// Verifica se a assinatura está expirada
  bool get isExpired {
    return status == SubscriptionStatus.expired ||
        expirationDate.isBefore(DateTime.now());
  }

  /// Calcula quantos dias faltam para expirar
  int get daysUntilExpiration {
    final now = DateTime.now();
    if (expirationDate.isBefore(now)) return 0;
    return expirationDate.difference(now).inDays;
  }

  /// Verifica se deve mostrar aviso de expiração (5 dias ou menos)
  bool get shouldShowWarning {
    return daysUntilExpiration <= 5 && daysUntilExpiration > 0;
  }
}
