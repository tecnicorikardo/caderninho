import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalAccount {
  PersonalAccount({
    required this.id,
    required this.nome,
    required this.saldoInicial,
    required this.criadoEm,
    required this.ativo,
  });

  final String id;
  final String nome;
  final double saldoInicial;
  final DateTime criadoEm;
  final bool ativo;

  factory PersonalAccount.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PersonalAccount(
      id: doc.id,
      nome: (data['nome'] ?? '') as String,
      saldoInicial: ((data['saldoInicial'] ?? 0) as num).toDouble(),
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ativo: (data['ativo'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'saldoInicial': saldoInicial,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'ativo': ativo,
    };
  }
}
