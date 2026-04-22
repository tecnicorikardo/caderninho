# Checklist de Testes - Cancelamento de Vendas

## ✅ Preparação
- [ ] Abrir terminal em `mobile_flutter`
- [ ] Executar: `flutter run -d chrome`
- [ ] Abrir Console do navegador (F12)
- [ ] Fazer login no sistema

---

## 🧪 Teste 1: Venda Livre Simples

### Passos
1. [ ] Ir para "Vendas"
2. [ ] Criar venda livre:
   - Descrição: "Teste cancelamento 1"
   - Valor: R$ 50,00
   - Pagamento: PIX
3. [ ] Registrar venda
4. [ ] Verificar que apareceu na lista
5. [ ] Clicar no botão cancelar (↶)
6. [ ] Confirmar cancelamento

### Resultado Esperado
- [ ] Venda removida da lista
- [ ] Mensagem: "Venda cancelada com sucesso"
- [ ] Sem erros no console
- [ ] Entrada financeira removida (verificar em "Financeiro")

**Status**: ⬜ Não testado | ✅ Passou | ❌ Falhou

**Observações**: _______________________________________________

---

## 🧪 Teste 2: Venda com Produto

### Preparação
- [ ] Criar produto teste (se não existir):
  - Nome: "Produto Teste"
  - Estoque: 10 unidades
  - Preço: R$ 25,00

### Passos
1. [ ] Ir para "Vendas"
2. [ ] Criar venda com produto:
   - Produto: "Produto Teste"
   - Quantidade: 2
   - Pagamento: Dinheiro
3. [ ] Anotar estoque antes: _____ unidades
4. [ ] Registrar venda
5. [ ] Verificar estoque depois: _____ unidades (deve ser -2)
6. [ ] Cancelar venda
7. [ ] Verificar estoque final: _____ unidades (deve voltar ao original)

### Resultado Esperado
- [ ] Venda removida
- [ ] Estoque restaurado corretamente
- [ ] Entrada financeira removida
- [ ] Mensagem de sucesso

**Status**: ⬜ Não testado | ✅ Passou | ❌ Falhou

**Observações**: _______________________________________________

---

## 🧪 Teste 3: Venda Fiada

### Passos
1. [ ] Ir para "Vendas"
2. [ ] Criar venda fiada:
   - Descrição: "Fiado teste"
   - Valor: R$ 100,00
   - Cliente: "Cliente Teste"
   - Pagamento: Fiado
3. [ ] Registrar venda
4. [ ] Ir para "Fiados" e verificar dívida criada
5. [ ] Voltar para "Vendas"
6. [ ] Cancelar venda
7. [ ] Voltar para "Fiados" e verificar

### Resultado Esperado
- [ ] Venda removida
- [ ] Dívida removida de "Fiados"
- [ ] Sem entrada financeira criada
- [ ] Mensagem de sucesso

**Status**: ⬜ Não testado | ✅ Passou | ❌ Falhou

**Observações**: _______________________________________________

---

## 🧪 Teste 4: Venda Fiada com Pagamento (deve falhar)

### Passos
1. [ ] Criar venda fiada de R$ 100,00
2. [ ] Ir para "Fiados"
3. [ ] Fazer pagamento parcial de R$ 30,00
4. [ ] Voltar para "Vendas"
5. [ ] Tentar cancelar a venda

### Resultado Esperado
- [ ] Cancelamento bloqueado
- [ ] Mensagem: "Não é possível cancelar: este fiado já recebeu pagamento"
- [ ] Venda permanece na lista
- [ ] Dívida permanece com saldo de R$ 70,00

**Status**: ⬜ Não testado | ✅ Passou | ❌ Falhou

**Observações**: _______________________________________________

---

## 🧪 Teste 5: Venda com Empréstimo

### Passos
1. [ ] Criar venda com empréstimo:
   - Descrição: "Empréstimo teste"
   - Valor: R$ 200,00
   - Cliente: "Cliente Teste"
   - Pagamento: Empréstimo
   - Vencimento: (data futura)
   - Taxa: 2% ao mês
2. [ ] Registrar venda
3. [ ] Verificar em "Empréstimos" que foi criado
4. [ ] Cancelar venda
5. [ ] Verificar em "Empréstimos"

### Resultado Esperado
- [ ] Venda removida
- [ ] Empréstimo removido
- [ ] Mensagem de sucesso

**Status**: ⬜ Não testado | ✅ Passou | ❌ Falhou

**Observações**: _______________________________________________

---

## 🧪 Teste 6: Múltiplas Vendas

### Passos
1. [ ] Criar 3 vendas diferentes:
   - Venda 1: Livre, PIX, R$ 30,00
   - Venda 2: Com produto, Dinheiro
   - Venda 3: Livre, Cartão, R$ 50,00
2. [ ] Cancelar todas as 3 vendas
3. [ ] Verificar lista de vendas
4. [ ] Verificar financeiro

### Resultado Esperado
- [ ] Todas as 3 vendas removidas
- [ ] Todas as entradas financeiras removidas
- [ ] Estoque restaurado (venda 2)
- [ ] Sem erros no console

**Status**: ⬜ Não testado | ✅ Passou | ❌ Falhou

**Observações**: _______________________________________________

---

## 📊 Resumo dos Testes

| Teste | Status | Observações |
|-------|--------|-------------|
| 1. Venda Livre | ⬜ | |
| 2. Venda com Produto | ⬜ | |
| 3. Venda Fiada | ⬜ | |
| 4. Fiada com Pagamento | ⬜ | |
| 5. Empréstimo | ⬜ | |
| 6. Múltiplas Vendas | ⬜ | |

**Total**: ___/6 testes passaram

---

## 🐛 Bugs Encontrados

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

---

## 📝 Notas Adicionais

_______________________________________________
_______________________________________________
_______________________________________________

---

## ✅ Aprovação Final

- [ ] Todos os testes passaram
- [ ] Sem erros no console
- [ ] Performance aceitável
- [ ] Pronto para deploy

**Testado por**: _______________________________________________

**Data**: _______________________________________________
