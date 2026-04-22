import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TipoTransacao { receita, despesa }

class PersonalCategory {
  PersonalCategory({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.icone,
    required this.cor,
    required this.criadoEm,
  });

  final String id;
  final String nome;
  final TipoTransacao tipo;
  final IconData icone;
  final Color cor;
  final DateTime criadoEm;

  static const List<IconData> supportedIcons = <IconData>[
    Icons.attach_money,
    Icons.shopping_cart,
    Icons.trending_up,
    Icons.restaurant,
    Icons.local_gas_station,
    Icons.home,
    Icons.directions_car,
    Icons.phone_android,
    Icons.local_hospital,
    Icons.school,
    Icons.fitness_center,
    Icons.movie,
    Icons.flight,
    Icons.pets,
    Icons.shopping_bag,
    Icons.credit_card,
  ];

  static IconData iconFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.attach_money;
    for (final icon in supportedIcons) {
      if (icon.codePoint == codePoint) {
        return icon;
      }
    }
    return Icons.attach_money;
  }

  factory PersonalCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PersonalCategory(
      id: doc.id,
      nome: (data['nome'] ?? '') as String,
      tipo: (data['tipo'] ?? 'despesa') == 'receita' 
          ? TipoTransacao.receita 
          : TipoTransacao.despesa,
      icone: iconFromCodePoint(data['icone'] as int?),
      cor: Color((data['cor'] ?? 0xFF2563EB) as int),
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo == TipoTransacao.receita ? 'receita' : 'despesa',
      'icone': icone.codePoint,
      'cor': cor.value,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  // Categorias padrão
  static List<PersonalCategory> defaultCategories() {
    final now = DateTime.now();
    return [
      // Receitas
      PersonalCategory(
        id: 'default_salario',
        nome: 'Salário',
        tipo: TipoTransacao.receita,
        icone: Icons.attach_money,
        cor: const Color(0xFF10B981),
        criadoEm: now,
      ),
      PersonalCategory(
        id: 'default_vendas',
        nome: 'Vendas',
        tipo: TipoTransacao.receita,
        icone: Icons.shopping_cart,
        cor: const Color(0xFF059669),
        criadoEm: now,
      ),
      PersonalCategory(
        id: 'default_investimentos',
        nome: 'Investimentos',
        tipo: TipoTransacao.receita,
        icone: Icons.trending_up,
        cor: const Color(0xFF047857),
        criadoEm: now,
      ),
      // Despesas
      PersonalCategory(
        id: 'default_alimentacao',
        nome: 'Alimentação',
        tipo: TipoTransacao.despesa,
        icone: Icons.restaurant,
        cor: const Color(0xFFEF4444),
        criadoEm: now,
      ),
      PersonalCategory(
        id: 'default_transporte',
        nome: 'Transporte',
        tipo: TipoTransacao.despesa,
        icone: Icons.directions_car,
        cor: const Color(0xFFDC2626),
        criadoEm: now,
      ),
      PersonalCategory(
        id: 'default_moradia',
        nome: 'Moradia',
        tipo: TipoTransacao.despesa,
        icone: Icons.home,
        cor: const Color(0xFFB91C1C),
        criadoEm: now,
      ),
      PersonalCategory(
        id: 'default_saude',
        nome: 'Saúde',
        tipo: TipoTransacao.despesa,
        icone: Icons.local_hospital,
        cor: const Color(0xFF991B1B),
        criadoEm: now,
      ),
      PersonalCategory(
        id: 'default_lazer',
        nome: 'Lazer',
        tipo: TipoTransacao.despesa,
        icone: Icons.movie,
        cor: const Color(0xFF7C2D12),
        criadoEm: now,
      ),
    ];
  }
}
