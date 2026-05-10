# 🚀 Testar Cancelamento de Vendas - AGORA! (REVISÃO 2)

## ⚠️ IMPORTANTE: Erro Corrigido

O primeiro teste deu erro porque tentamos fazer query dentro de transação do Firestore.
**Isso foi CORRIGIDO!** Agora deve funcionar.

Veja detalhes em: `CORRECAO_ERRO_TRANSACAO.md`

---

## ⚡ Comandos Rápidos

### 0. Limpar Cache (IMPORTANTE!)
```bash
cd mobile_flutter
flutter clean
flutter pub get
```

### 1. Testar na Web (Chrome)
```bash
flutter run -d chrome
```

### 2. Build para Web
```bash
cd mobile_flutter
flutter build web
```

### 3. Servir com Firebase
```bash
firebase serve
```

---

## 📝 Checklist Rápido

### ✅ Teste Básico (5 minutos)
1. [ ] Criar venda livre (PIX, R$ 50)
2. [ ] Cancelar venda
3. [ ] Verificar se foi removida
4. [ ] Verificar financeiro

### ✅ Teste com Produto (5 minutos)
1. [ ] Criar produto (10 unidades)
2. [ ] Vender 2 unidades
3. [ ] Cancelar venda
4. [ ] Verificar estoque voltou para 10

### ✅ Teste Fiado (3 minutos)
1. [ ] Criar venda fiada (R$ 100)
2. [ ] Cancelar venda
3. [ ] Verificar que dívida foi removida

---

## 🐛 Se Der Erro

### Console do Navegador (F12)
- Procure por erros em vermelho
- Copie a mensagem de erro
- Verifique se é "permission-denied" ou "not-found"

### Erros Comuns

**"Permission denied"**
→ Problema nas regras do Firestore
→ Verifique se está logado

**"Venda não encontrada"**
→ Recarregue a página
→ Venda pode já ter sido deletada

**Estoque não restaura**
→ Verifique se produto existe
→ Veja console para erros

---

## 📊 Resultado Esperado

### ✅ Sucesso
- Venda removida da lista
- Mensagem: "Venda cancelada com sucesso"
- Sem erros no console
- Entrada financeira removida
- Estoque restaurado (se produto)

### ❌ Falha
- Venda permanece na lista
- Mensagem de erro aparece
- Erros no console
- Entrada financeira não removida

---

## 📞 Próximos Passos

### Se Funcionou ✅
1. Testar todos os cenários do `test_cancelamento.md`
2. Testar no mobile (Android/iOS)
3. Fazer deploy para produção

### Se Não Funcionou ❌
1. Copiar erro do console
2. Verificar `ultimacorrecao.md` → Troubleshooting
3. Ajustar código conforme necessário
4. Testar novamente

---

## 📁 Arquivos Importantes

- `ultimacorrecao.md` - Documentação completa das correções
- `mobile_flutter/test_cancelamento.md` - Checklist detalhado de testes
- `mobile_flutter/lib/src/core/app_store.dart` - Código modificado

---

## 🎯 Foco do Teste

**Objetivo**: Verificar se o cancelamento de vendas está funcionando

**Tempo estimado**: 15-20 minutos para testes básicos

**Prioridade**: 
1. Venda livre (mais comum)
2. Venda com produto (importante para estoque)
3. Venda fiada (importante para dívidas)

---

## ✨ Boa Sorte!

Qualquer problema, consulte `ultimacorrecao.md` para troubleshooting detalhado.
