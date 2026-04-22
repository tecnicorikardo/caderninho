import 'package:cloud_firestore/cloud_firestore.dart';

class WebhookLogModel {
  WebhookLogModel({
    required this.id,
    required this.type,
    required this.action,
    required this.data,
    required this.processed,
    this.error,
    required this.createdAt,
    this.processedAt,
  });

  final String id;
  final String type;
  final String action;
  final Map<String, dynamic> data;
  final bool processed;
  final String? error;
  final DateTime createdAt;
  final DateTime? processedAt;

  factory WebhookLogModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return WebhookLogModel(
      id: doc.id,
      type: (data['type'] ?? '') as String,
      action: (data['action'] ?? '') as String,
      data: (data['data'] ?? {}) as Map<String, dynamic>,
      processed: (data['processed'] ?? false) as bool,
      error: data['error'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'action': action,
      'data': data,
      'processed': processed,
      if (error != null) 'error': error,
      'createdAt': Timestamp.fromDate(createdAt),
      if (processedAt != null) 'processedAt': Timestamp.fromDate(processedAt!),
    };
  }

  WebhookLogModel copyWith({
    String? id,
    String? type,
    String? action,
    Map<String, dynamic>? data,
    bool? processed,
    String? error,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return WebhookLogModel(
      id: id ?? this.id,
      type: type ?? this.type,
      action: action ?? this.action,
      data: data ?? this.data,
      processed: processed ?? this.processed,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  /// Verifica se o webhook foi processado com sucesso
  bool get isProcessedSuccessfully => processed && error == null;

  /// Verifica se o webhook teve erro
  bool get hasError => error != null;

  /// Verifica se o webhook está pendente de processamento
  bool get isPending => !processed;
}
