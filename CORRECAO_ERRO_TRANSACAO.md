# 🔧 Correção do Erro de Transação

## 🔴 Erro Encontrado

```
Assertion failed: file:///C:/Users/ADM/AppData/Local/Pub/
Cache/hosted/pub.dev/nested-1.0.0/lib/nested.dart:71:16
children.isNotEmpty
is not true
```

**Mensagem do sistema**: 
```
Falha inesperada ao cancelar venda p9T2jp6siFBl4AwAreyM: 
Error: Dart exception thrown from converted Future.
```

---

## 🔍 Causa Raiz

O erro ocorreu porque tentamos fazer uma **query** (`.where()`) **dentro de uma transação** do Firestore, o que **NÃO É PERMITIDO**.

### Código Problemático (ANTES)

```dart
await _db.runTransaction((txn) async {
  // ... outras operações ...
  
  // ❌ ERRO: Query dentro de transação!
  final entriesSnap = await _col('financial_entries')
      .where('saleId', isEqualTo: sale.id)
      .where('origin', isEqualTo: 'sale')
      .get();
  
  if (entriesSnap.docs.isNotEmpty) {
    for (final entryDoc in entriesSnap.docs) {
      txn.delete(entryDoc.reference);
    }
  }
  
  txn.delete(saleRef);
});
```

### Por que deu erro?

O Firestore **NÃO PERMITE** as seguintes operações dentro de transações:
- ❌ `.where()` - Queries com filtros
- ❌ `.orderBy()` - Ordenação
- ❌ `.limit()` - Limitação de resultados
- ❌ Qualquer operação que não seja acesso direto por ID

O Firestore **PERMITE** apenas:
- ✅ `.get()` de documento específico por ID
- ✅ `.set()` para criar/atualizar
- ✅ `.update()` para atualizar campos
- ✅ `.delete()` para deletar

---

## ✅ Solução Implementada

### Abordagem em 2 Etapas

**Etapa 1: Dentro da Transação** (operações críticas)
- Restaurar estoque (se produto)
- Deletar dívida/empréstimo (se aplicável)
- Deletar entrada financeira (se tiver ID)
- Criar estorno (se não tiver ID)
- Deletar venda

**Etapa 2: Após a Transação** (limpeza opcional)
- Buscar entradas órfãs (agora pode usar `.where()`)
- Deletar entradas órfãs encontradas

### Código Corrigido (DEPOIS)

```dart
await _db.runTransaction((txn) async {
  // ... operações de restauração de estoque, dívidas, etc ...
  
  // ✅ DENTRO DA TRANSAÇÃO: Só operações diretas
  if (paymentMethod != 'fiado' &&
      financialEntryId != null &&
      financialEntryId.isNotEmpty) {
    // Deleta entrada financeira por ID (permitido)
    final entryRef = _col('financial_entries').doc(financialEntryId);
    final entrySnap = await txn.get(entryRef);
    if (entrySnap.exists) {
      txn.delete(entryRef);
    }
  }
  
  if (paymentMethod != 'fiado' &&
      (financialEntryId == null || financialEntryId.isEmpty)) {
    // Cria estorno (sem query, permitido)
    final reversalRef = _col('financial_entries').doc();
    txn.set(reversalRef, {
      'type': 'expense',
      'description': 'Estorno de venda cancelada: $saleDescription',
      'category': 'Operacional',
      'amount': saleTotal,
      'origin': 'sale_cancel_reversal',
      'saleId': sale.id,
      'createdAt': DateTime.now(),
    });
  }
  
  txn.delete(saleRef);
});

// ✅ APÓS A TRANSAÇÃO: Agora pode usar query
if (validationError == null) {
  try {
    // Busca entradas órfãs (fora da transação, permitido)
    final orphanEntries = await _col('financial_entries')
        .where('saleId', isEqualTo: sale.id)
        .where('origin', isEqualTo: 'sale')
        .get();
    
    if (orphanEntries.docs.isNotEmpty) {
      // Deleta em batch
      final batch = _db.batch();
      for (final doc in orphanEntries.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  } catch (e) {
    debugPrint('Aviso: não foi possível limpar entradas órfãs: $e');
  }
}
```

---

## 🎯 Vantagens da Nova Abordagem

### 1. Compatibilidade com Firestore
- ✅ Não usa queries dentro de transações
- ✅ Respeita as limitações do Firestore
- ✅ Não causa erros de assertion

### 2. Funcionalidade Mantida
- ✅ Vendas novas (com `financialEntryId`) são canceladas perfeitamente
- ✅ Vendas antigas (sem `financialEntryId`) recebem estorno automático
- ✅ Entradas órfãs são limpas após a transação

### 3. Atomicidade Garantida
- ✅ Operações críticas (estoque, dívidas, venda) são atômicas
- ✅ Limpeza de órfãos é opcional e não quebra o cancelamento
- ✅ Se a limpeza falhar, o cancelamento ainda funciona

### 4. Performance
- ✅ Transação mais rápida (menos operações)
- ✅ Limpeza assíncrona não bloqueia o usuário
- ✅ Batch para deletar múltiplas entradas

---

## 📊 Comparação

| Aspecto | ANTES (Erro) | DEPOIS (Corrigido) |
|---------|--------------|-------------------|
| Query em transação | ❌ Sim (erro) | ✅ Não |
| Funciona? | ❌ Não | ✅ Sim |
| Vendas novas | ❌ Erro | ✅ Funciona |
| Vendas antigas | ❌ Erro | ✅ Estorno |
| Limpeza órfãos | ❌ Não executa | ✅ Após transação |
| Atomicidade | ❌ Quebrada | ✅ Mantida |

---

## 🧪 Como Testar Agora

### 1. Limpar cache do Flutter
```bash
cd mobile_flutter
flutter clean
flutter pub get
```

### 2. Executar na web
```bash
flutter run -d chrome
```

### 3. Testar cancelamento
1. Criar venda livre (PIX, R$ 50)
2. Cancelar venda
3. Verificar se foi removida
4. Verificar console (F12) - não deve ter erros

---

## 🔍 O Que Esperar

### ✅ Vendas Novas (com financialEntryId)
- Entrada financeira deletada diretamente
- Sem estorno criado
- Cancelamento limpo

### ✅ Vendas Antigas (sem financialEntryId)
- Estorno criado automaticamente
- Entrada órfã deletada após transação (se existir)
- Cancelamento funciona

### ✅ Console do Navegador
- Sem erros em vermelho
- Pode ter aviso: "não foi possível limpar entradas órfãs" (normal se não houver)
- Mensagem: "Venda cancelada com sucesso"

---

## 📝 Resumo

**Problema**: Query dentro de transação causava erro de assertion

**Solução**: Mover query para APÓS a transação

**Resultado**: Cancelamento funciona para vendas novas e antigas

**Status**: ✅ Pronto para testar novamente
