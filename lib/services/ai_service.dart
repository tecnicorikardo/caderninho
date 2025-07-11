import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/produto.dart';
import '../models/venda.dart';
import '../models/cliente.dart';

/// Serviço para integração com IA
class AIService {
  static final AIService _instancia = AIService._interno();
  factory AIService() => _instancia;
  AIService._interno();

  // ✅ CONFIGURAÇÃO PARA OPENAI/IA GENERATIVA
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey = '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';
  
  // Headers padrão
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
  };

  /// 🔍 ANALISAR DADOS DE VENDAS PARA SUGESTÕES
  Future<List<SugestaoIA>> analisarVendas(List<Venda> vendas) async {
    try {
      final prompt = _criarPromptAnaliseVendas(vendas);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Você é um assistente especializado em análise de vendas para pequenos comerciantes. Analise os dados e forneça sugestões práticas e acionáveis.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parsearSugestoesIA(content);
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao analisar vendas: $e');
      return [];
    }
  }

  /// 📦 SUGERIR REPOSIÇÃO DE ESTOQUE
  Future<List<SugestaoEstoque>> sugerirReposicao(List<Produto> produtos) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sugerir-estoque'),
        headers: _headers,
        body: jsonEncode({
          'produtos': produtos.map((p) => p.toMap()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['sugestoes'] as List)
            .map((item) => SugestaoEstoque.fromMap(item))
            .toList();
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao sugerir reposição: $e');
      return [];
    }
  }

  /// 💰 OTIMIZAR PREÇOS
  Future<List<OtimizacaoPreco>> otimizarPrecos(List<Produto> produtos) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/otimizar-precos'),
        headers: _headers,
        body: jsonEncode({
          'produtos': produtos.map((p) => p.toMap()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['otimizacoes'] as List)
            .map((item) => OtimizacaoPreco.fromMap(item))
            .toList();
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao otimizar preços: $e');
      return [];
    }
  }

  /// 🎯 RECOMENDAÇÕES PERSONALIZADAS
  Future<List<Recomendacao>> gerarRecomendacoes(Cliente cliente, List<Venda> historico) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recomendacoes'),
        headers: _headers,
        body: jsonEncode({
          'cliente': cliente.toMap(),
          'historico': historico.map((v) => v.toMap()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['recomendacoes'] as List)
            .map((item) => Recomendacao.fromMap(item))
            .toList();
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao gerar recomendações: $e');
      return [];
    }
  }

  /// 📊 ANÁLISE DE TENDÊNCIAS
  Future<AnaliseTendencias> analisarTendencias(List<Venda> vendas) async {
    try {
      final prompt = _criarPromptTendencias(vendas);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Você é um analista de dados especializado em identificar tendências de vendas para pequenos comerciantes.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.5,
          'max_tokens': 800
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parsearAnaliseTendencias(content);
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao analisar tendências: $e');
      return AnaliseTendencias.empty();
    }
  }

  // ============ MÉTODOS AUXILIARES ============

  /// 📝 CRIAR PROMPT PARA ANÁLISE DE VENDAS
  String _criarPromptAnaliseVendas(List<Venda> vendas) {
    final totalVendas = vendas.length;
    final valorTotal = vendas.fold(0.0, (sum, v) => sum + v.total);
    final vendasPorDia = _agruparVendasPorDia(vendas);
    
    final vendasPorDiaStr = vendasPorDia.entries.map((entry) => 
        '- ${entry.key}: ${entry.value.length} vendas (R\$ ${entry.value.fold(0.0, (sum, v) => sum + v.total).toStringAsFixed(2)})').join('\n');
    
    return '''
Analise os dados de vendas do comerciante e forneça 3-5 sugestões práticas para melhorar o negócio.

DADOS DAS VENDAS:
- Total de vendas: $totalVendas
- Valor total: R\$ ${valorTotal.toStringAsFixed(2)}
- Período: ${vendas.isNotEmpty ? vendas.first.dataVenda.toString() : 'N/A'} até ${vendas.isNotEmpty ? vendas.last.dataVenda.toString() : 'N/A'}

VENDAS POR DIA:
$vendasPorDiaStr

PRODUTOS MAIS VENDIDOS:
${_getProdutosMaisVendidos(vendas)}

Forneça sugestões em formato JSON:
{
  "sugestoes": [
    {
      "tipo": "estoque|preco|promocao|cliente",
      "titulo": "Título da sugestão",
      "descricao": "Descrição detalhada",
      "confianca": 0.85,
      "dados": {}
    }
  ]
}
''';
  }

  /// 📝 CRIAR PROMPT PARA ANÁLISE DE TENDÊNCIAS
  String _criarPromptTendencias(List<Venda> vendas) {
    final produtosMaisVendidos = _getProdutosMaisVendidos(vendas);
    final vendasPorDia = _agruparVendasPorDia(vendas);
    
    final vendasPorDiaStr = vendasPorDia.entries.map((entry) => 
        '- ${entry.key}: ${entry.value.length} vendas').join('\n');
    
    return '''
Analise as tendências de vendas e identifique padrões importantes.

DADOS PARA ANÁLISE:
${produtosMaisVendidos}

VENDAS POR DIA:
$vendasPorDiaStr

Forneça análise em formato JSON:
{
  "produtosEmAlta": ["produto1", "produto2"],
  "produtosEmBaixa": ["produto3"],
  "crescimentoVendas": 15.5,
  "periodoAnalisado": "últimos 30 dias",
  "insights": {
    "melhorDia": "segunda-feira",
    "picoVendas": "14:00-16:00",
    "recomendacao": "Descrição da recomendação"
  }
}
''';
  }

  /// 🔍 AGRUPAR VENDAS POR DIA
  Map<String, List<Venda>> _agruparVendasPorDia(List<Venda> vendas) {
    final Map<String, List<Venda>> vendasPorDia = {};
    
    for (final venda in vendas) {
      final data = venda.dataVenda.toIso8601String().split('T')[0];
      vendasPorDia.putIfAbsent(data, () => []).add(venda);
    }
    
    return vendasPorDia;
  }

  /// 📦 OBTER PRODUTOS MAIS VENDIDOS
  String _getProdutosMaisVendidos(List<Venda> vendas) {
    final Map<String, int> contagemProdutos = {};
    
    for (final venda in vendas) {
      for (final item in venda.itens) {
        contagemProdutos[item.produto.nome] = 
            (contagemProdutos[item.produto.nome] ?? 0) + item.quantidade;
      }
    }
    
    final sorted = contagemProdutos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(5).map((entry) => 
        '- ${entry.key}: ${entry.value} unidades').join('\n');
  }

  /// 🔄 PARSEAR SUGESTÕES DA IA
  List<SugestaoIA> _parsearSugestoesIA(String content) {
    try {
      // Tentar extrair JSON da resposta
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = content.substring(jsonStart, jsonEnd + 1);
        final data = jsonDecode(jsonStr);
        
        return (data['sugestoes'] as List)
            .map((item) => SugestaoIA.fromMap(item))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Erro ao parsear sugestões: $e');
    }
    
    // Fallback: criar sugestão genérica
    return [
      SugestaoIA(
        tipo: 'geral',
        titulo: 'Análise Completa',
        descricao: content,
        confianca: 0.7,
        dados: {},
      )
    ];
  }

  /// 🔄 PARSEAR ANÁLISE DE TENDÊNCIAS
  AnaliseTendencias _parsearAnaliseTendencias(String content) {
    try {
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = content.substring(jsonStart, jsonEnd + 1);
        final data = jsonDecode(jsonStr);
        return AnaliseTendencias.fromMap(data);
      }
    } catch (e) {
      debugPrint('❌ Erro ao parsear tendências: $e');
    }
    
    return AnaliseTendencias.empty();
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

  factory SugestaoIA.fromMap(Map<String, dynamic> map) {
    return SugestaoIA(
      tipo: map['tipo'] ?? '',
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      confianca: (map['confianca'] ?? 0.0).toDouble(),
      dados: map['dados'] ?? {},
    );
  }
}

class SugestaoEstoque {
  final String produtoId;
  final String nomeProduto;
  final int quantidadeAtual;
  final int quantidadeSugerida;
  final String motivo;
  final double urgencia; // 0.0 a 1.0

  SugestaoEstoque({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidadeAtual,
    required this.quantidadeSugerida,
    required this.motivo,
    required this.urgencia,
  });

  factory SugestaoEstoque.fromMap(Map<String, dynamic> map) {
    return SugestaoEstoque(
      produtoId: map['produtoId'] ?? '',
      nomeProduto: map['nomeProduto'] ?? '',
      quantidadeAtual: map['quantidadeAtual'] ?? 0,
      quantidadeSugerida: map['quantidadeSugerida'] ?? 0,
      motivo: map['motivo'] ?? '',
      urgencia: (map['urgencia'] ?? 0.0).toDouble(),
    );
  }
}

class OtimizacaoPreco {
  final String produtoId;
  final String nomeProduto;
  final double precoAtual;
  final double precoSugerido;
  final String justificativa;
  final double impactoEsperado; // Percentual

  OtimizacaoPreco({
    required this.produtoId,
    required this.nomeProduto,
    required this.precoAtual,
    required this.precoSugerido,
    required this.justificativa,
    required this.impactoEsperado,
  });

  factory OtimizacaoPreco.fromMap(Map<String, dynamic> map) {
    return OtimizacaoPreco(
      produtoId: map['produtoId'] ?? '',
      nomeProduto: map['nomeProduto'] ?? '',
      precoAtual: (map['precoAtual'] ?? 0.0).toDouble(),
      precoSugerido: (map['precoSugerido'] ?? 0.0).toDouble(),
      justificativa: map['justificativa'] ?? '',
      impactoEsperado: (map['impactoEsperado'] ?? 0.0).toDouble(),
    );
  }
}

class Recomendacao {
  final String tipo; // 'produto', 'promocao', 'acao'
  final String titulo;
  final String descricao;
  final double relevancia;
  final Map<String, dynamic> dados;

  Recomendacao({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.relevancia,
    required this.dados,
  });

  factory Recomendacao.fromMap(Map<String, dynamic> map) {
    return Recomendacao(
      tipo: map['tipo'] ?? '',
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      relevancia: (map['relevancia'] ?? 0.0).toDouble(),
      dados: map['dados'] ?? {},
    );
  }
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

  factory AnaliseTendencias.fromMap(Map<String, dynamic> map) {
    return AnaliseTendencias(
      produtosEmAlta: List<String>.from(map['produtosEmAlta'] ?? []),
      produtosEmBaixa: List<String>.from(map['produtosEmBaixa'] ?? []),
      crescimentoVendas: (map['crescimentoVendas'] ?? 0.0).toDouble(),
      periodoAnalisado: map['periodoAnalisado'] ?? '',
      insights: map['insights'] ?? {},
    );
  }

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