# Última Atualização - Recurso de Venda Rápida (Nova Funcionalidade)

## Data: Hoje

## Nova Funcionalidade Implementada

### Adição da Venda Rápida no Dashboard
Foi adicionado um Botão Flutuante secundário (⚡ Venda Rápida) acima do botão de Resumo do Dia no `dashboard_screen.dart`.
Ao clicar, é exibido um Bottom Sheet (Gaveta inferior) otimizado usando o arquivo `fast_sale_modal.dart` (novo).

A gaveta compreende um fluxo rápido e sem burocracia para vendas de balcão ou caixa rápido:
- Escolher o produto buscando o nome/categoria.
- Selecionar a quantidade com botões de adição (+) e (-).
- Dois botões grandes e diretos visando economizar 2 ou 3 passos na tela de originais de vendas: [ DINHEIRO ] e [ PIX ].
- As vendas criam as instâncias de Estoque, de Sales e Financeiro corretamente usando `registerProductSale` sob os panos.

## Arquivos Modificados/Criados
- [Novo] `mobile_flutter/lib/src/features/home/widgets/fast_sale_modal.dart`
- [Modificado] `mobile_flutter/lib/src/features/home/dashboard_screen.dart` — FAB transformado em Column com 2 botões

## Correção de Bug Famoso (children.isNotEmpty)
O erro da tela vermelha "children.isNotEmpty is not true" que impedia o uso do app (e que antes relatamos aparecer junto com a "Transação do Firestore") na verdade vinha do pacote UI `nested` (usado pelo `Provider`). 
Ele ocorria quando o app tentava carregar a árvore de widgets sem um usuário logado (passando uma lista vazia de provedores).
- **Solução**: Ajustei o `app.dart` para só injetar o `MultiProvider` se houver um `user` autenticado. Problema resolvido para sempre, tanto no fluxo de logout quanto no login inicial!
- **Arquivo modificado**: `mobile_flutter/lib/src/app.dart`

---

# Última Correção - Importação de Produtos XLSX (REVISÃO 4)

## Data: 14/03/2026

## Problemas Corrigidos

### 1. Build error: importação dupla de `StorageDirectory`
`export_service.dart` importava `io_stub.dart` e `path_provider_stub.dart`, e ambos definiam `StorageDirectory`, causando conflito de compilação.

**Solução**: Removido `StorageDirectory` do `io_stub.dart`. Agora ele só existe em `path_provider_stub.dart` (stub web) e em `path_provider` (mobile real).

### 2. Runtime error: `Excel.decodeBytes()` null pointer em arquivos .xlsx modernos
O pacote `excel: ^4.0.6` tem bug com arquivos `.xlsx` gerados pelo Excel/Google Sheets modernos (null dereference interno).

**Solução**: Adicionado fallback em `_decodeSpreadsheet`:
- Tenta `Excel.decodeBytes()` normalmente
- Se falhar, tenta tratar os bytes como CSV
- Se ambos falharem, exibe mensagem clara pedindo para salvar como CSV

## Arquivos Modificados
- `mobile_flutter/lib/src/features/subscription/services/io_stub.dart` — removido `StorageDirectory`
- `mobile_flutter/lib/src/features/subscription/services/path_provider_stub.dart` — mantém `StorageDirectory`
- `mobile_flutter/lib/src/features/subscription/services/export_service.dart` — fallback CSV no decode

## Status
✅ Build web passou sem erros
✅ Deploy feito em https://bloquinhodigital.web.app

## Orientação ao usuário
Se o arquivo `.xlsx` ainda falhar (o fallback CSV pode não funcionar para todos os casos),
peça ao usuário para salvar o arquivo como **CSV UTF-8** no Excel/Google Sheets antes de importar.
