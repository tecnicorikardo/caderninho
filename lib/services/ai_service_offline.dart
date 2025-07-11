import 'package:flutter/foundation.dart';
import '../models/produto.dart';
import '../models/venda.dart';
import '../models/cliente.dart';

/// Serviço de IA que funciona offline
class AIOfflineService {
  static final AIOfflineService _instancia = AIOfflineService._interno();
  factory AIOfflineService() => _instancia;
  AIOfflineService._interno();

  /// 🔍 ANALISAR DADOS DE VENDAS PARA SUGESTÕES
  Future<List<SugestaoIA>> analisarVendas(List<Venda> vendas) async {
    try {
      if (vendas.isEmpty) {
        return [
          SugestaoIA(
            tipo: 'geral',
            titulo: 'Nenhuma venda encontrada',
            descricao: 'Adicione vendas para obter análises e sugestões.',
            confianca: 1.0,
            dados: {},
          )
        ];
      }

      final sugestoes = <SugestaoIA>[];
      
      // Análise de estoque
      final sugestoesEstoque = _analisarEstoque(vendas);
      sugestoes.addAll(sugestoesEstoque);
      
      // Análise de vendas
      final sugestoesVendas = _analisarPadroesVendas(vendas);
      sugestoes.addAll(sugestoesVendas);
      
      // Análise de produtos
      final sugestoesProdutos = _analisarProdutos(vendas);
      sugestoes.addAll(sugestoesProdutos);
      
      // Análise de clientes
      final sugestoesClientes = _analisarClientes(vendas);
      sugestoes.addAll(sugestoesClientes);

      return sugestoes;
    } catch (e) {
      debugPrint('❌ Erro ao analisar vendas offline: $e');
      return [];
    }
  }

  /// 📊 ANÁLISE DE TENDÊNCIAS
  Future<AnaliseTendencias> analisarTendencias(List<Venda> vendas) async {
    try {
      if (vendas.isEmpty) {
        return AnaliseTendencias.empty();
      }

      final produtosMaisVendidos = _getProdutosMaisVendidos(vendas);
      final produtosMenosVendidos = _getProdutosMenosVendidos(vendas);
      final crescimentoVendas = _calcularCrescimentoVendas(vendas);
      final insights = _gerarInsights(vendas);

      return AnaliseTendencias(
        produtosEmAlta: produtosMaisVendidos,
        produtosEmBaixa: produtosMenosVendidos,
        crescimentoVendas: crescimentoVendas,
        periodoAnalisado: 'últimos ${vendas.length} dias',
        insights: insights,
      );
    } catch (e) {
      debugPrint('❌ Erro ao analisar tendências offline: $e');
      return AnaliseTendencias.empty();
    }
  }

  // ============ MÉTODOS DE ANÁLISE ============

  List<SugestaoIA> _analisarEstoque(List<Venda> vendas) {
    final sugestoes = <SugestaoIA>[];
    final produtosVendidos = <String, int>{};
    
    // Contar produtos vendidos
    for (final venda in vendas) {
      for (final item in venda.itens) {
        produtosVendidos[item.produto.nome] = 
            (produtosVendidos[item.produto.nome] ?? 0) + item.quantidade;
      }
    }

    // Identificar produtos com alta demanda
    final produtosAltaDemanda = produtosVendidos.entries
        .where((entry) => entry.value > 10)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final produto in produtosAltaDemanda.take(3)) {
      sugestoes.add(SugestaoIA(
        tipo: 'estoque',
        titulo: 'Repor estoque: ${produto.key}',
        descricao: 'Produto com alta demanda (${produto.value} unidades vendidas). Considere aumentar o estoque.',
        confianca: 0.8,
        dados: {'produto': produto.key, 'quantidade': produto.value},
      ));
    }

    return sugestoes;
  }

  List<SugestaoIA> _analisarPadroesVendas(List<Venda> vendas) {
    final sugestoes = <SugestaoIA>[];
    
    // Análise de valor médio por venda
    final valorMedio = vendas.fold(0.0, (sum, v) => sum + v.total) / vendas.length;
    
    if (valorMedio < 50) {
      sugestoes.add(SugestaoIA(
        tipo: 'promocao',
        titulo: 'Aumentar ticket médio',
        descricao: 'Ticket médio baixo (R\$ ${valorMedio.toStringAsFixed(2)}). Considere combos e promoções.',
        confianca: 0.7,
        dados: {'valorMedio': valorMedio},
      ));
    }

    // Análise de frequência de vendas
    final vendasPorDia = _agruparVendasPorDia(vendas);
    final diasComVendas = vendasPorDia.length;
    
    if (diasComVendas < 3) {
      sugestoes.add(SugestaoIA(
        tipo: 'marketing',
        titulo: 'Aumentar frequência de vendas',
        descricao: 'Vendas em apenas $diasComVendas dias. Considere estratégias de marketing.',
        confianca: 0.6,
        dados: {'diasComVendas': diasComVendas},
      ));
    }

    return sugestoes;
  }

  List<SugestaoIA> _analisarProdutos(List<Venda> vendas) {
    final sugestoes = <SugestaoIA>[];
    final produtosVendidos = <String, double>{};
    
    // Calcular receita por produto
    for (final venda in vendas) {
      for (final item in venda.itens) {
        produtosVendidos[item.produto.nome] = 
            (produtosVendidos[item.produto.nome] ?? 0) + item.total;
      }
    }

    // Identificar produtos mais lucrativos
    final produtosOrdenados = produtosVendidos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (produtosOrdenados.isNotEmpty) {
      final produtoTop = produtosOrdenados.first;
      sugestoes.add(SugestaoIA(
        tipo: 'produto',
        titulo: 'Focar no produto: ${produtoTop.key}',
        descricao: 'Produto com maior receita (R\$ ${produtoTop.value.toStringAsFixed(2)}). Considere expandir a linha.',
        confianca: 0.9,
        dados: {'produto': produtoTop.key, 'receita': produtoTop.value},
      ));
    }

    return sugestoes;
  }

  List<SugestaoIA> _analisarClientes(List<Venda> vendas) {
    final sugestoes = <SugestaoIA>[];
    final clientesFrequentes = <String, int>{};
    
    // Contar vendas por cliente
    for (final venda in vendas) {
      if (venda.cliente != null) {
        clientesFrequentes[venda.cliente!.nome] = 
            (clientesFrequentes[venda.cliente!.nome] ?? 0) + 1;
      }
    }

    // Identificar clientes fiéis
    final clientesOrdenados = clientesFrequentes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (clientesOrdenados.isNotEmpty && clientesOrdenados.first.value > 2) {
      final clienteTop = clientesOrdenados.first;
      sugestoes.add(SugestaoIA(
        tipo: 'cliente',
        titulo: 'Cliente fiel: ${clienteTop.key}',
        descricao: 'Cliente com ${clienteTop.value} compras. Considere programa de fidelidade.',
        confianca: 0.8,
        dados: {'cliente': clienteTop.key, 'compras': clienteTop.value},
      ));
    }

    return sugestoes;
  }

  List<String> _getProdutosMaisVendidos(List<Venda> vendas) {
    final produtosVendidos = <String, int>{};
    
    for (final venda in vendas) {
      for (final item in venda.itens) {
        produtosVendidos[item.produto.nome] = 
            (produtosVendidos[item.produto.nome] ?? 0) + item.quantidade;
      }
    }

    final sorted = produtosVendidos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(3).map((entry) => entry.key).toList();
  }

  List<String> _getProdutosMenosVendidos(List<Venda> vendas) {
    final produtosVendidos = <String, int>{};
    
    for (final venda in vendas) {
      for (final item in venda.itens) {
        produtosVendidos[item.produto.nome] = 
            (produtosVendidos[item.produto.nome] ?? 0) + item.quantidade;
      }
    }

    final sorted = produtosVendidos.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return sorted.take(2).map((entry) => entry.key).toList();
  }

  double _calcularCrescimentoVendas(List<Venda> vendas) {
    if (vendas.length < 2) return 0.0;
    
    final vendasOrdenadas = List<Venda>.from(vendas)
      ..sort((a, b) => a.dataVenda.compareTo(b.dataVenda));
    
    final primeiraMetade = vendasOrdenadas.take(vendasOrdenadas.length ~/ 2);
    final segundaMetade = vendasOrdenadas.skip(vendasOrdenadas.length ~/ 2);
    
    final valorPrimeiraMetade = primeiraMetade.fold(0.0, (sum, v) => sum + v.total);
    final valorSegundaMetade = segundaMetade.fold(0.0, (sum, v) => sum + v.total);
    
    if (valorPrimeiraMetade == 0) return 0.0;
    
    return ((valorSegundaMetade - valorPrimeiraMetade) / valorPrimeiraMetade) * 100;
  }

  Map<String, dynamic> _gerarInsights(List<Venda> vendas) {
    final insights = <String, dynamic>{};
    
    // Melhor dia da semana
    final vendasPorDia = <int, int>{};
    for (final venda in vendas) {
      final diaSemana = venda.dataVenda.weekday;
      vendasPorDia[diaSemana] = (vendasPorDia[diaSemana] ?? 0) + 1;
    }
    
    if (vendasPorDia.isNotEmpty) {
      final melhorDia = vendasPorDia.entries
          .reduce((a, b) => a.value > b.value ? a : b).key;
      
      final diasSemana = ['domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'];
      insights['melhorDia'] = diasSemana[melhorDia % 7];
    }
    
    // Valor médio por venda
    final valorMedio = vendas.fold(0.0, (sum, v) => sum + v.total) / vendas.length;
    insights['valorMedio'] = valorMedio.toStringAsFixed(2);
    
    // Total de vendas
    insights['totalVendas'] = vendas.length;
    
    return insights;
  }

  Map<String, List<Venda>> _agruparVendasPorDia(List<Venda> vendas) {
    final Map<String, List<Venda>> vendasPorDia = {};
    
    for (final venda in vendas) {
      final data = venda.dataVenda.toIso8601String().split('T')[0];
      vendasPorDia.putIfAbsent(data, () => []).add(venda);
    }
    
    return vendasPorDia;
  }
}

/// 📋 MODELOS DE DADOS PARA IA

class SugestaoIA {
  final String tipo;
  final String titulo;
  final String descricao;
  final double confianca;
  final Map<String, dynamic> dados;

  SugestaoIA({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.confianca,
    required this.dados,
  });
}

class AnaliseTendencias {
  final List<String> produtosEmAlta;
  final List<String> produtosEmBaixa;
  final double crescimentoVendas;
  final String periodoAnalisado;
  final Map<String, dynamic> insights;

  AnaliseTendencias({
    required this.produtosEmAlta,
    required this.produtosEmBaixa,
    required this.crescimentoVendas,
    required this.periodoAnalisado,
    required this.insights,
  });

  factory AnaliseTendencias.empty() {
    return AnaliseTendencias(
      produtosEmAlta: [],
      produtosEmBaixa: [],
      crescimentoVendas: 0.0,
      periodoAnalisado: '',
      insights: {},
    );
  }
} 