import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

// dart:io: File, Directory, Platform
import 'io_stub.dart' if (dart.library.io) 'dart:io';

// path_provider: getApplicationDocumentsDirectory, getExternalStorageDirectories,
// getExternalStorageDirectory, StorageDirectory
import 'path_provider_stub.dart'
    if (dart.library.io) 'package:path_provider/path_provider.dart';

import '../../../core/app_store.dart';
import '../../../core/utils/search_utils.dart';
import '../../products/product_pricing_analysis.dart';
import '../../products/recipe_pricing_models.dart';

class ImportedCustomerRow {
  ImportedCustomerRow({required this.name, required this.phone});
  final String name;
  final String phone;
}

class ImportedProductRow {
  ImportedProductRow({
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.brandName,
    required this.situation,
    required this.hasSituation,
    required this.description,
    required this.sizeLabel,
    required this.variation,
    required this.salePrice,
    required this.cost,
    required this.commissionPercent,
    required this.automaticDiscountPercent,
    required this.stock,
    required this.stockMinimum,
    required this.expiryDate,
    required this.batchCode,
    required this.storageLocation,
    required this.unit,
    required this.showInWeb,
    required this.notes,
  });
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String brandName;
  final ProductSituation situation;
  final bool hasSituation;
  final String description;
  final String sizeLabel;
  final String variation;
  final double salePrice;
  final double cost;
  final double commissionPercent;
  final double automaticDiscountPercent;
  final double stock;
  final double stockMinimum;
  final DateTime? expiryDate;
  final String batchCode;
  final String storageLocation;
  final String unit;
  final bool showInWeb;
  final String notes;
}

class _PickedSpreadsheetFile {
  const _PickedSpreadsheetFile({
    required this.bytes,
    required this.source,
    required this.name,
    required this.size,
    this.extension,
    this.path,
  });
  final Uint8List bytes;
  final String source;
  final String name;
  final int size;
  final String? extension;
  final String? path;
}

class ExportService {
  // ─── EXPORTAÇÕES ────────────────────────────────────────────────────────────

  Future<String?> exportCustomers(List<CustomerRecord> customers) async {
    final excel = Excel.createExcel();
    final sheet = excel['Clientes'];
    sheet.appendRow([
      TextCellValue('Nome'),
      TextCellValue('Telefone'),
      TextCellValue('Status'),
      TextCellValue('Data de Cadastro'),
    ]);
    for (final c in customers) {
      sheet.appendRow([
        TextCellValue(c.name),
        TextCellValue(c.phone),
        TextCellValue(c.isActive ? 'Ativo' : 'Inativo'),
        TextCellValue(
          '${c.createdAt.day.toString().padLeft(2, '0')}/${c.createdAt.month.toString().padLeft(2, '0')}/${c.createdAt.year}',
        ),
      ]);
    }
    return _saveExcel(excel, 'clientes.xlsx');
  }

  Future<String?> exportProducts(List<ProductRecord> products) async {
    final excel = Excel.createExcel();
    final sheet = excel['Produtos'];
    sheet.appendRow([
      TextCellValue('Nome'),
      TextCellValue('SKU'),
      TextCellValue('Codigo de Barras'),
      TextCellValue('Categoria'),
      TextCellValue('Marca'),
      TextCellValue('Situacao'),
      TextCellValue('Descricao'),
      TextCellValue('Tamanho'),
      TextCellValue('Variacao'),
      TextCellValue('Preco de Venda'),
      TextCellValue('Custo'),
      TextCellValue('Comissao (%)'),
      TextCellValue('Desconto Automatico (%)'),
      TextCellValue('Estoque'),
      TextCellValue('Estoque Minimo'),
      TextCellValue('Validade'),
      TextCellValue('Lote'),
      TextCellValue('Localizacao'),
      TextCellValue('Unidade'),
      TextCellValue('Lucro Estimado'),
      TextCellValue('Margem de Lucro'),
      TextCellValue('Vitrine'),
      TextCellValue('Observacoes'),
    ]);
    for (final p in products) {
      final margin = p.cost > 0 ? ((p.salePrice - p.cost) / p.cost * 100) : 0.0;
      sheet.appendRow([
        TextCellValue(p.name),
        TextCellValue(p.sku),
        TextCellValue(p.barcode),
        TextCellValue(p.category),
        TextCellValue(p.brandName),
        TextCellValue(p.situation.label),
        TextCellValue(p.description),
        TextCellValue(p.sizeLabel),
        TextCellValue(p.variation),
        TextCellValue('R\$ ${p.salePrice.toStringAsFixed(2)}'),
        TextCellValue('R\$ ${p.cost.toStringAsFixed(2)}'),
        DoubleCellValue(p.commissionPercent),
        DoubleCellValue(p.automaticDiscountPercent),
        TextCellValue(p.stock.toStringAsFixed(2)),
        TextCellValue(p.stockMinimum.toStringAsFixed(2)),
        TextCellValue(
          p.expiryDate == null
              ? ''
              : '${p.expiryDate!.day.toString().padLeft(2, '0')}/${p.expiryDate!.month.toString().padLeft(2, '0')}/${p.expiryDate!.year}',
        ),
        TextCellValue(p.batchCode),
        TextCellValue(p.storageLocation),
        TextCellValue(p.unit),
        TextCellValue('R\$ ${p.estimatedProfitPerUnit.toStringAsFixed(2)}'),
        TextCellValue('${margin.toStringAsFixed(2)}%'),
        TextCellValue(p.showInWeb ? 'Sim' : 'Nao'),
        TextCellValue(p.notes),
      ]);
    }
    return _saveExcel(excel, 'produtos.xlsx');
  }

  Future<String?> exportProductPricing(
    List<ProductRecord> products, {
    required double targetMarginPercent,
  }) async {
    final safeTarget = ProductPricingCalculator.normalizeTargetMargin(
      targetMarginPercent,
    );
    final analyses =
        products
            .map(
              (p) => ProductPricingCalculator.analyze(
                p,
                targetMarginPercent: safeTarget,
              ),
            )
            .toList()
          ..sort((a, b) {
            if (a.isBelowTarget != b.isBelowTarget)
              return a.isBelowTarget ? -1 : 1;
            return a.product.name.toLowerCase().compareTo(
              b.product.name.toLowerCase(),
            );
          });
    final summary = ProductPricingCalculator.summarize(
      products,
      targetMarginPercent: safeTarget,
    );

    final excel = Excel.createExcel();
    final detailsSheet = excel['Precificacao'];
    detailsSheet.appendRow([
      TextCellValue('Nome'),
      TextCellValue('Categoria'),
      TextCellValue('Custo'),
      TextCellValue('Preco atual'),
      TextCellValue('Lucro por unidade'),
      TextCellValue('Markup atual (%)'),
      TextCellValue('Margem atual (%)'),
      TextCellValue('Margem alvo (%)'),
      TextCellValue('Preco sugerido'),
      TextCellValue('Ajuste necessario'),
      TextCellValue('Ajuste (%)'),
      TextCellValue('Estoque'),
      TextCellValue('Receita potencial atual'),
      TextCellValue('Receita potencial sugerida'),
      TextCellValue('Lucro potencial atual'),
      TextCellValue('Status'),
    ]);
    for (final a in analyses) {
      detailsSheet.appendRow([
        TextCellValue(a.product.name),
        TextCellValue(a.product.category),
        DoubleCellValue(a.product.cost),
        DoubleCellValue(a.product.salePrice),
        DoubleCellValue(a.profitPerUnit),
        DoubleCellValue(a.markupPercent),
        DoubleCellValue(a.marginPercent),
        DoubleCellValue(a.targetMarginPercent),
        DoubleCellValue(a.suggestedPrice),
        DoubleCellValue(a.adjustmentValue),
        DoubleCellValue(a.adjustmentPercent),
        DoubleCellValue(a.product.stock),
        DoubleCellValue(a.potentialRevenue),
        DoubleCellValue(a.suggestedPotentialRevenue),
        DoubleCellValue(a.potentialProfit),
        TextCellValue(a.statusLabel),
      ]);
    }

    final summarySheet = excel['Resumo'];
    summarySheet.appendRow([
      TextCellValue('Indicador'),
      TextCellValue('Valor'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Produtos analisados'),
      IntCellValue(summary.totalProducts),
    ]);
    summarySheet.appendRow([
      TextCellValue('Margem alvo (%)'),
      DoubleCellValue(safeTarget),
    ]);
    summarySheet.appendRow([
      TextCellValue('Produtos abaixo da meta'),
      IntCellValue(summary.productsBelowTarget),
    ]);
    summarySheet.appendRow([
      TextCellValue('Receita potencial atual'),
      DoubleCellValue(summary.currentPotentialRevenue),
    ]);
    summarySheet.appendRow([
      TextCellValue('Lucro potencial atual'),
      DoubleCellValue(summary.currentPotentialProfit),
    ]);
    summarySheet.appendRow([
      TextCellValue('Receita potencial sugerida'),
      DoubleCellValue(summary.suggestedPotentialRevenue),
    ]);
    summarySheet.appendRow([
      TextCellValue('Impacto potencial'),
      DoubleCellValue(summary.suggestedRevenueDelta),
    ]);
    summarySheet.appendRow([
      TextCellValue('Margem media atual (%)'),
      DoubleCellValue(summary.averageMarginPercent),
    ]);

    return _saveExcel(excel, 'precificacao_produtos.xlsx');
  }

  Future<String?> exportRecipeTechnicalSheets(
    List<RecipeTechnicalSheet> recipes,
  ) async {
    final excel = Excel.createExcel();
    final summarySheet = excel['FichasTecnicas'];
    summarySheet.appendRow([
      TextCellValue('Receita'),
      TextCellValue('Rendimento'),
      TextCellValue('Margem alvo (%)'),
      TextCellValue('Ingredientes'),
      TextCellValue('Custo ingredientes'),
      TextCellValue('Custos extras'),
      TextCellValue('Custo total'),
      TextCellValue('Preco sugerido'),
      TextCellValue('Lucro sugerido'),
      TextCellValue('Status'),
      TextCellValue('Atualizado em'),
    ]);
    final ingredientsSheet = excel['Ingredientes'];
    ingredientsSheet.appendRow([
      TextCellValue('Receita'),
      TextCellValue('Ingrediente'),
      TextCellValue('Compra'),
      TextCellValue('Uso na receita'),
      TextCellValue('Perda (%)'),
      TextCellValue('Custo calculado'),
      TextCellValue('Observacao'),
    ]);
    for (final recipe in recipes) {
      final analysis = RecipePricingCalculator.analyzeSheet(recipe);
      final normalizedMargin = RecipePricingCalculator.normalizeMargin(
        recipe.targetMarginPercent,
      );
      summarySheet.appendRow([
        TextCellValue(recipe.name),
        TextCellValue(
          '${recipe.yieldQuantity.toStringAsFixed(2)} ${recipe.yieldUnit.label}',
        ),
        DoubleCellValue(normalizedMargin),
        IntCellValue(recipe.ingredients.length),
        DoubleCellValue(analysis.ingredientsCost),
        DoubleCellValue(recipe.additionalCost),
        DoubleCellValue(analysis.totalCost),
        DoubleCellValue(analysis.suggestedPrice),
        DoubleCellValue(analysis.suggestedProfit),
        TextCellValue(analysis.statusLabel),
        TextCellValue(
          '${recipe.updatedAt.day.toString().padLeft(2, '0')}/${recipe.updatedAt.month.toString().padLeft(2, '0')}/${recipe.updatedAt.year}',
        ),
      ]);
      for (final ia in analysis.ingredients) {
        final ing = ia.ingredient;
        ingredientsSheet.appendRow([
          TextCellValue(recipe.name),
          TextCellValue(ing.name),
          TextCellValue(
            '${ing.purchaseQuantity.toStringAsFixed(2)} ${ing.purchaseUnit.label} por ${ing.purchaseCost.toStringAsFixed(2)}',
          ),
          TextCellValue(
            '${ing.usageQuantity.toStringAsFixed(2)} ${ing.usageUnit.label}',
          ),
          DoubleCellValue(ing.wastePercent),
          DoubleCellValue(ia.totalCost),
          TextCellValue(ia.issue ?? ''),
        ]);
      }
    }
    return _saveExcel(excel, 'fichas_tecnicas_receitas.xlsx');
  }

  Future<String?> exportReports({
    required List<SaleRecord> sales,
    required List<FinancialEntry> finances,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();

    final salesSheet = excel['Vendas'];
    salesSheet.appendRow([
      TextCellValue('Data'),
      TextCellValue('Hora'),
      TextCellValue('Descricao'),
      TextCellValue('Cliente'),
      TextCellValue('Valor'),
      TextCellValue('Forma de Pagamento'),
    ]);
    for (final s in sales) {
      salesSheet.appendRow([
        TextCellValue(
          '${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year}',
        ),
        TextCellValue(
          '${s.createdAt.hour.toString().padLeft(2, '0')}:${s.createdAt.minute.toString().padLeft(2, '0')}',
        ),
        TextCellValue(s.description),
        TextCellValue(s.customerName ?? ''),
        TextCellValue('R\$ ${s.total.toStringAsFixed(2)}'),
        TextCellValue(s.paymentMethod),
      ]);
    }

    final financeSheet = excel['Financeiro'];
    financeSheet.appendRow([
      TextCellValue('Data'),
      TextCellValue('Tipo'),
      TextCellValue('Categoria'),
      TextCellValue('Descricao'),
      TextCellValue('Valor'),
    ]);
    for (final f in finances) {
      financeSheet.appendRow([
        TextCellValue(
          '${f.createdAt.day.toString().padLeft(2, '0')}/${f.createdAt.month.toString().padLeft(2, '0')}/${f.createdAt.year}',
        ),
        TextCellValue(
          f.type == FinancialEntryType.revenue ? 'Receita' : 'Despesa',
        ),
        TextCellValue(f.category),
        TextCellValue(f.description),
        TextCellValue('R\$ ${f.amount.toStringAsFixed(2)}'),
      ]);
    }

    final summarySheet = excel['Resumo'];
    final totalSales = sales.fold<double>(0, (s, e) => s + e.total);
    final totalRevenue = finances
        .where((f) => f.type == FinancialEntryType.revenue)
        .fold<double>(0, (s, e) => s + e.amount);
    final totalExpense = finances
        .where((f) => f.type == FinancialEntryType.expense)
        .fold<double>(0, (s, e) => s + e.amount);
    summarySheet.appendRow([
      TextCellValue('Periodo'),
      TextCellValue(
        '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year} - ${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
      ),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total de Vendas'),
      TextCellValue('R\$ ${totalSales.toStringAsFixed(2)}'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total de Receitas'),
      TextCellValue('R\$ ${totalRevenue.toStringAsFixed(2)}'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total de Despesas'),
      TextCellValue('R\$ ${totalExpense.toStringAsFixed(2)}'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Lucro Liquido'),
      TextCellValue('R\$ ${(totalRevenue - totalExpense).toStringAsFixed(2)}'),
    ]);

    return _saveExcel(excel, 'relatorios.xlsx');
  }

  // ─── IMPORTAÇÕES ────────────────────────────────────────────────────────────

  /// Gera e baixa um arquivo XLSX de modelo para importação de clientes.
  Future<void> exportCustomerTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['clientes'];
    sheet.appendRow([TextCellValue('nome'), TextCellValue('telefone')]);
    sheet.appendRow([
      TextCellValue('Ricardo Silva'),
      TextCellValue('11999998888'),
    ]);
    sheet.appendRow([
      TextCellValue('Maria Souza'),
      TextCellValue('21988887777'),
    ]);
    await _saveExcel(excel, 'modelo_clientes.xlsx');
  }

  Future<List<ImportedCustomerRow>> importCustomersFromSpreadsheet() async {
    final pickedFile = await _pickSpreadsheetFile();
    if (pickedFile == null) return const [];

    final excel = _decodeSpreadsheet(pickedFile);
    final table = _findSheet(excel, const ['clientes', 'customer']);
    if (table == null || table.rows.isEmpty) {
      throw Exception('Planilha de clientes vazia ou invalida.');
    }

    final headers = _headerIndex(table.rows.first);
    final nameIndex = _findColumn(headers, const ['nome', 'cliente', 'name']);
    final phoneIndex = _findColumn(headers, const [
      'telefone',
      'celular',
      'phone',
      'whatsapp',
    ]);

    if (nameIndex == null) {
      throw Exception('Coluna de nome nao encontrada na planilha de clientes.');
    }

    final imported = <ImportedCustomerRow>[];
    for (final row in table.rows.skip(1)) {
      final name = _cellAt(row, nameIndex);
      if (name.isEmpty) continue;
      imported.add(
        ImportedCustomerRow(
          name: name,
          phone: phoneIndex == null ? '' : _cellAt(row, phoneIndex),
        ),
      );
    }
    return imported;
  }

  /// Gera e baixa um arquivo XLSX de modelo para importação de produtos.
  /// O arquivo é criado pelo mesmo pacote excel, garantindo compatibilidade.
  Future<void> exportProductTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['produtos'];
    sheet.appendRow([
      TextCellValue('nome'),
      TextCellValue('sku'),
      TextCellValue('codigo_barras'),
      TextCellValue('categoria'),
      TextCellValue('marca'),
      TextCellValue('situacao'),
      TextCellValue('descricao'),
      TextCellValue('tamanho'),
      TextCellValue('variacao'),
      TextCellValue('preco_venda'),
      TextCellValue('custo'),
      TextCellValue('comissao'),
      TextCellValue('desconto_automatico'),
      TextCellValue('estoque'),
      TextCellValue('estoque_minimo'),
      TextCellValue('validade'),
      TextCellValue('lote'),
      TextCellValue('localizacao'),
      TextCellValue('unidade'),
      TextCellValue('vitrine'),
      TextCellValue('observacoes'),
    ]);
    // Linhas de exemplo
    sheet.appendRow([
      TextCellValue('Colonia Lily'),
      TextCellValue('BOT-LILY-100'),
      TextCellValue('7890001112223'),
      TextCellValue('Perfumes'),
      TextCellValue('O Boticario'),
      TextCellValue('Novo lancamento'),
      TextCellValue('Perfume feminino floral'),
      TextCellValue('100 ml'),
      TextCellValue('Tradicional'),
      TextCellValue('189.90'),
      TextCellValue('120.00'),
      TextCellValue('15'),
      TextCellValue('0'),
      TextCellValue('8'),
      TextCellValue('2'),
      TextCellValue('15/12/2026'),
      TextCellValue('L2026-01'),
      TextCellValue('Prateleira A1'),
      TextCellValue('un'),
      TextCellValue('sim'),
      TextCellValue('Produto com boa saida'),
    ]);
    sheet.appendRow([
      TextCellValue('Batom Glam'),
      TextCellValue('EUD-BAT-014'),
      TextCellValue('7890003334445'),
      TextCellValue('Cosmeticos'),
      TextCellValue('Eudora'),
      TextCellValue('Promocao'),
      TextCellValue('Batom matte longa duracao'),
      TextCellValue('3.5 g'),
      TextCellValue('Vermelho'),
      TextCellValue('39.90'),
      TextCellValue('21.50'),
      TextCellValue('20'),
      TextCellValue('10'),
      TextCellValue('15'),
      TextCellValue('4'),
      TextCellValue('01/10/2026'),
      TextCellValue('BAT-552'),
      TextCellValue('Gaveta 2'),
      TextCellValue('un'),
      TextCellValue('sim'),
      TextCellValue('Edicao promocional'),
    ]);
    await _saveExcel(excel, 'modelo_produtos.xlsx');
  }

  Future<List<ImportedProductRow>> importProductsFromSpreadsheet() async {
    final pickedFile = await _pickSpreadsheetFile();
    if (pickedFile == null) return const [];

    final excel = _decodeSpreadsheet(pickedFile);
    final table = _findSheet(excel, const ['produtos', 'products', 'estoque']);
    if (table == null || table.rows.isEmpty) {
      throw Exception('Planilha de produtos vazia ou invalida.');
    }

    final headers = _headerIndex(table.rows.first);
    final nameIndex = _findColumn(headers, const ['nome', 'produto', 'name']);
    final skuIndex = _findColumn(headers, const [
      'sku',
      'codigo',
      'codigo_sku',
    ]);
    final barcodeIndex = _findColumn(headers, const [
      'codigo_barras',
      'cod_barras',
      'barcode',
      'ean',
    ]);
    final categoryIndex = _findColumn(headers, const ['categoria', 'category']);
    final brandIndex = _findColumn(headers, const [
      'marca',
      'empresa',
      'brand',
    ]);
    final situationIndex = _findColumn(headers, const [
      'situacao',
      'status_produto',
      'product_situation',
    ]);
    final descriptionIndex = _findColumn(headers, const [
      'descricao',
      'descricao_completa',
      'description',
    ]);
    final sizeIndex = _findColumn(headers, const [
      'tamanho',
      'ml',
      'volume',
      'size',
    ]);
    final variationIndex = _findColumn(headers, const [
      'variacao',
      'cor',
      'variant',
      'variation',
    ]);
    final salePriceIndex = _findColumn(headers, const [
      'preco_de_venda',
      'preco_venda',
      'valor_venda',
      'venda',
      'preco',
      'sale_price',
      'saleprice',
    ]);
    final costIndex = _findColumn(headers, const [
      'custo',
      'preco_de_custo',
      'valor_custo',
      'cost',
    ]);
    final commissionIndex = _findColumn(headers, const [
      'comissao',
      'comissao_percentual',
      'commission',
    ]);
    final automaticDiscountIndex = _findColumn(headers, const [
      'desconto_automatico',
      'desconto',
      'automatic_discount',
      'discount',
    ]);
    final stockIndex = _findColumn(headers, const [
      'estoque',
      'qtd',
      'quantidade',
      'stock',
    ]);
    final stockMinimumIndex = _findColumn(headers, const [
      'estoque_minimo',
      'minimo',
      'stock_minimum',
      'estoque_min',
    ]);
    final expiryDateIndex = _findColumn(headers, const [
      'validade',
      'data_validade',
      'expiry_date',
      'expiry',
    ]);
    final batchCodeIndex = _findColumn(headers, const [
      'lote',
      'batch',
      'batch_code',
    ]);
    final storageLocationIndex = _findColumn(headers, const [
      'localizacao',
      'local_estoque',
      'storage_location',
      'endereco_estoque',
    ]);
    final unitIndex = _findColumn(headers, const ['unidade', 'unit']);
    final showInWebIndex = _findColumn(headers, const [
      'vitrine',
      'show_in_web',
      'showinweb',
    ]);
    final notesIndex = _findColumn(headers, const [
      'observacoes',
      'observacao',
      'notas',
      'notes',
    ]);

    if (nameIndex == null) {
      throw Exception('Coluna de nome nao encontrada na planilha de produtos.');
    }

    final imported = <ImportedProductRow>[];
    for (final row in table.rows.skip(1)) {
      final name = _cellAt(row, nameIndex);
      if (name.isEmpty) continue;
      imported.add(
        ImportedProductRow(
          name: name,
          sku: skuIndex == null ? '' : _cellAt(row, skuIndex),
          barcode: barcodeIndex == null ? '' : _cellAt(row, barcodeIndex),
          category: categoryIndex == null
              ? 'Geral'
              : (_cellAt(row, categoryIndex).isEmpty
                    ? 'Geral'
                    : _cellAt(row, categoryIndex)),
          brandName: brandIndex == null ? '' : _cellAt(row, brandIndex),
          situation: _parseProductSituation(
            situationIndex == null ? '' : _cellAt(row, situationIndex),
          ),
          hasSituation:
              situationIndex != null &&
              _cellAt(row, situationIndex).trim().isNotEmpty,
          description: descriptionIndex == null
              ? ''
              : _cellAt(row, descriptionIndex),
          sizeLabel: sizeIndex == null ? '' : _cellAt(row, sizeIndex),
          variation: variationIndex == null ? '' : _cellAt(row, variationIndex),
          salePrice: _parseDecimal(
            salePriceIndex == null ? '' : _cellAt(row, salePriceIndex),
          ),
          cost: _parseDecimal(costIndex == null ? '' : _cellAt(row, costIndex)),
          commissionPercent: _parseDecimal(
            commissionIndex == null ? '' : _cellAt(row, commissionIndex),
          ),
          automaticDiscountPercent: _parseDecimal(
            automaticDiscountIndex == null
                ? ''
                : _cellAt(row, automaticDiscountIndex),
          ),
          stock: _parseDecimal(
            stockIndex == null ? '' : _cellAt(row, stockIndex),
          ),
          stockMinimum: _parseDecimal(
            stockMinimumIndex == null ? '' : _cellAt(row, stockMinimumIndex),
          ),
          expiryDate: _parseOptionalDate(
            expiryDateIndex == null ? '' : _cellAt(row, expiryDateIndex),
          ),
          batchCode: batchCodeIndex == null ? '' : _cellAt(row, batchCodeIndex),
          storageLocation: storageLocationIndex == null
              ? ''
              : _cellAt(row, storageLocationIndex),
          unit: unitIndex == null
              ? 'un'
              : (_cellAt(row, unitIndex).isEmpty
                    ? 'un'
                    : _cellAt(row, unitIndex)),
          showInWeb: _parseBool(
            showInWebIndex == null ? '' : _cellAt(row, showInWebIndex),
          ),
          notes: notesIndex == null ? '' : _cellAt(row, notesIndex),
        ),
      );
    }
    return imported;
  }

  // ─── LEITURA DE ARQUIVO ─────────────────────────────────────────────────────

  Future<_PickedSpreadsheetFile?> _pickSpreadsheetFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      // withData: true garante bytes disponíveis em TODAS as plataformas,
      // especialmente no Web onde file.path não existe.
      withData: true,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
    );

    if (result == null || result.files.isEmpty) {
      debugPrint('[Import] Selecao cancelada.');
      return null;
    }

    final file = result.files.first;
    final extension = (file.extension ?? '').toLowerCase();

    debugPrint(
      '[Import] Arquivo: nome=${file.name}, ext=$extension, size=${file.size}, hasBytes=${file.bytes != null}, isWeb=$kIsWeb',
    );

    // WEB: NUNCA usar path — sempre bytes
    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception(
          'Nao foi possivel ler o arquivo no navegador. Tente novamente.',
        );
      }
      debugPrint('[Import] Web: ${bytes.length} bytes lidos.');
      return _PickedSpreadsheetFile(
        bytes: bytes,
        source: 'bytes_web',
        name: file.name,
        extension: extension.isEmpty ? null : extension,
        path: null,
        size: file.size,
      );
    }

    // MOBILE/DESKTOP: bytes primeiro, path como fallback
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      debugPrint(
        '[Import] Mobile/Desktop: ${file.bytes!.length} bytes em memoria.',
      );
      return _PickedSpreadsheetFile(
        bytes: file.bytes!,
        source: 'bytes',
        name: file.name,
        extension: extension.isEmpty ? null : extension,
        path: file.path,
        size: file.size,
      );
    }

    if (file.path != null && file.path!.trim().isNotEmpty) {
      try {
        final pathBytes = Uint8List.fromList(
          await File(file.path!).readAsBytes(),
        );
        if (pathBytes.isNotEmpty) {
          debugPrint(
            '[Import] Mobile/Desktop: ${pathBytes.length} bytes via path.',
          );
          return _PickedSpreadsheetFile(
            bytes: pathBytes,
            source: 'path',
            name: file.name,
            extension: extension.isEmpty ? null : extension,
            path: file.path,
            size: file.size,
          );
        }
      } catch (e) {
        debugPrint('[Import] Falha ao ler via path: $e');
      }
    }

    throw Exception(
      'Nao foi possivel ler o arquivo. Tente um XLSX ou CSV salvo localmente.',
    );
  }

  // ─── DECODE / PARSE ─────────────────────────────────────────────────────────

  /// Decodifica XLSX ou CSV para objeto Excel.
  Excel _decodeSpreadsheet(_PickedSpreadsheetFile f) {
    final ext = (f.extension ?? '').toLowerCase();

    // CSV: converter bytes → string → parsear
    if (ext == 'csv') return _parseCsvToExcel(f.bytes, f.name);

    // XLSX/XLS: tentar decodificar; se falhar, tentar como CSV (fallback)
    try {
      final excel = Excel.decodeBytes(f.bytes);
      debugPrint(
        '[Import] "${f.name}" decodificado. Abas: ${excel.tables.length}',
      );
      return excel;
    } catch (e) {
      debugPrint('[Import] Falha ao decodificar "${f.name}" como XLSX: $e');
      debugPrint('[Import] Tentando fallback CSV...');
      // Alguns arquivos .xlsx gerados por Excel/Google Sheets moderno causam
      // null pointer no pacote excel. Tentamos tratar como CSV como fallback.
      try {
        final csvExcel = _parseCsvToExcel(f.bytes, f.name);
        debugPrint('[Import] Fallback CSV funcionou para "${f.name}"');
        return csvExcel;
      } catch (csvErr) {
        debugPrint('[Import] Fallback CSV tambem falhou: $csvErr');
      }
      throw Exception(
        'Nao foi possivel ler "${f.name}".\n'
        'Tente salvar o arquivo como CSV (UTF-8) no Excel ou Google Sheets e importe novamente.\n'
        'Erro tecnico: $e',
      );
    }
  }

  /// Converte bytes CSV em objeto Excel com aba "Sheet1".
  Excel _parseCsvToExcel(Uint8List bytes, String fileName) {
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final separator = content.contains(';') ? ';' : ',';
    final lines = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) throw Exception('Arquivo CSV "$fileName" esta vazio.');

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    for (final line in lines) {
      sheet.appendRow(
        _splitCsvLine(line, separator).map(TextCellValue.new).toList(),
      );
    }
    debugPrint(
      '[Import] CSV "$fileName": ${lines.length} linhas, sep="$separator"',
    );
    return excel;
  }

  /// Divide linha CSV respeitando campos entre aspas.
  List<String> _splitCsvLine(String line, String sep) {
    final fields = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == sep && !inQuotes) {
        fields.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    fields.add(buf.toString().trim());
    return fields;
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  Sheet? _findSheet(Excel excel, List<String> expectedNames) {
    for (final entry in excel.tables.entries) {
      final normalized = normalizeForSearch(entry.key).replaceAll(' ', '_');
      for (final expected in expectedNames) {
        if (normalized.contains(expected)) return entry.value;
      }
    }
    for (final table in excel.tables.values) {
      if (table.rows.isNotEmpty) return table;
    }
    return excel.tables.values.isEmpty ? null : excel.tables.values.first;
  }

  Map<String, int> _headerIndex(List<dynamic> headerRow) {
    final index = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final label = normalizeForSearch(
        _cellText(headerRow[i]),
      ).replaceAll(' ', '_');
      if (label.isNotEmpty) index[label] = i;
    }
    return index;
  }

  int? _findColumn(Map<String, int> headerIndex, List<String> aliases) {
    for (final alias in aliases) {
      final normalized = normalizeForSearch(alias).replaceAll(' ', '_');
      final direct = headerIndex[normalized];
      if (direct != null) return direct;
      for (final entry in headerIndex.entries) {
        if (entry.key.contains(normalized)) return entry.value;
      }
    }
    return null;
  }

  String _cellAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return _cellText(row[index]);
  }

  String _cellText(dynamic cell) {
    if (cell == null) return '';
    dynamic value;
    try {
      value = cell.value;
    } catch (_) {
      value = cell;
    }
    if (value == null) return '';
    if (value is TextCellValue) return value.value.toString().trim();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value ? 'true' : 'false';
    final text = value.toString().trim();
    // Remove wrapper "TextCellValue(value: foo)" → "foo"
    final m = RegExp(r'^[A-Za-z]+CellValue\(value:\s*(.*)\)$').firstMatch(text);
    if (m != null) return (m.group(1) ?? '').trim();
    return text;
  }

  double _parseDecimal(String raw) {
    var t = raw.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (t.isEmpty) return 0;
    final hasComma = t.contains(',');
    final hasDot = t.contains('.');
    if (hasComma && hasDot) {
      t = t.lastIndexOf(',') > t.lastIndexOf('.')
          ? t.replaceAll('.', '').replaceAll(',', '.')
          : t.replaceAll(',', '');
    } else if (hasComma) {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t) ?? 0;
  }

  DateTime? _parseOptionalDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  ProductSituation _parseProductSituation(String raw) {
    final value = normalizeLookupKey(raw);
    switch (value) {
      case 'novo':
      case 'novo_lancamento':
      case 'lancamento':
        return ProductSituation.newRelease;
      case 'antigo':
      case 'antiga':
        return ProductSituation.old;
      case 'promocao':
      case 'promo':
        return ProductSituation.promotion;
      case 'queima':
      case 'queima_de_estoque':
        return ProductSituation.clearance;
      case 'fora_de_linha':
      case 'descontinuado':
        return ProductSituation.discontinued;
      case 'atual':
      default:
        return ProductSituation.current;
    }
  }

  bool _parseBool(String value) {
    final t = normalizeLookupKey(value);
    return t == '1' ||
        t == 'true' ||
        t == 'sim' ||
        t == 'yes' ||
        t == 'ativo' ||
        t == 'on';
  }

  // ─── SALVAR EXCEL ───────────────────────────────────────────────────────────

  /// Web: faz download no navegador. Mobile/Desktop: salva em disco.
  Future<String?> _saveExcel(Excel excel, String filename) async {
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Erro ao gerar arquivo Excel');

    if (kIsWeb) {
      final blob = html.Blob([
        bytes,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      debugPrint('[Export] Download: $filename');
      return null;
    }

    final directory = await _resolveExportDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    debugPrint('[Export] Salvo: ${file.path}');

    // Compartilha o arquivo via seletor nativo (Android/iOS)
    await Share.shareXFiles([
      XFile(
        file.path,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    ], subject: filename);

    return file.path;
  }

  Future<Directory> _resolveExportDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) return dirs.first;
      } catch (_) {}
      try {
        final dir = await getExternalStorageDirectory();
        if (dir != null) return dir;
      } catch (_) {}
    }
    return getApplicationDocumentsDirectory();
  }
}
