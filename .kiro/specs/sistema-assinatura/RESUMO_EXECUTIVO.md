# Resumo Executivo: Sistema de Assinatura Bloquinho Digital

## 📋 Visão Geral

Transformar o Bloquinho Digital em um SaaS com modelo de assinatura, oferecendo 2 meses gratuitos para novos usuários e 3 planos pagos integrados com Mercado Pago.

## 💰 Modelo de Negócio

### Planos Oferecidos

| Plano | Preço | Período | Economia |
|-------|-------|---------|----------|
| **Gratuito** | R$ 0,00 | 2 meses | - |
| **Mensal** | R$ 29,90 | 1 mês | - |
| **Trimestral** | R$ 49,90 | 3 meses | 44% |
| **Anual** | R$ 299,90 | 12 meses | 16% |

### Projeção de Receita (Exemplo)

**Cenário Conservador** (100 usuários pagantes):
- 60 usuários mensais: R$ 1.794,00/mês
- 30 usuários trimestrais: R$ 499,00/mês (R$ 1.497,00 a cada 3 meses)
- 10 usuários anuais: R$ 249,92/mês (R$ 2.999,00 por ano)

**Receita Mensal Estimada**: ~R$ 2.543,00
**Receita Anual Estimada**: ~R$ 30.516,00

## 🎯 Funcionalidades Principais

### 1. Período Gratuito Automático
- Todo novo usuário recebe 2 meses grátis
- Sem necessidade de cartão de crédito
- Acesso completo a todas as funcionalidades

### 2. Sistema de Notificações
- Banner aparece 5 dias antes da expiração
- Mensagem clara sobre o que acontecerá
- Botão direto para renovação

### 3. Acesso Limitado Pós-Expiração
**Usuários com assinatura expirada PODEM:**
- ✅ Visualizar todos os dados
- ✅ Exportar clientes para Excel
- ✅ Exportar produtos para Excel
- ✅ Exportar relatórios para Excel

**Usuários com assinatura expirada NÃO PODEM:**
- ❌ Adicionar novos registros
- ❌ Editar dados existentes
- ❌ Registrar vendas
- ❌ Adicionar despesas

### 4. Integração Mercado Pago
- Pagamento 100% automatizado
- Suporte a cartão, PIX e boleto
- Webhooks para atualização automática
- Sem necessidade de intervenção manual

### 5. Suporte ao Cliente
- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074
- Botões diretos na tela de configurações

## 🔧 Arquitetura Técnica

### Frontend (Flutter Web/Mobile)
- Tela de assinatura com 3 planos
- Banner de expiração responsivo
- Bloqueio de funcionalidades baseado em status
- Exportação de dados para Excel

### Backend (Firebase)
- **Firestore**: Armazenamento de dados de assinatura
- **Functions**: Processamento de webhooks e validações
- **Authentication**: Controle de usuários

### Integração
- **Mercado Pago SDK**: Processamento de pagamentos
- **Webhooks**: Atualização automática de status

## 📊 Modelo de Dados

### Coleção: `users/{userId}/subscription`

```javascript
{
  plan: "free" | "monthly" | "quarterly" | "annual",
  status: "active" | "expired" | "trial",
  startDate: Timestamp,
  expirationDate: Timestamp,
  autoRenew: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Coleção: `users/{userId}/transactions`

```javascript
{
  transactionId: string,
  mercadoPagoId: string,
  plan: string,
  amount: number,
  status: "pending" | "approved" | "rejected",
  paymentMethod: string,
  createdAt: Timestamp,
  processedAt: Timestamp
}
```

## 🚀 Fluxo de Implementação

### Fase 1: Estrutura Base (2-3 dias)
- [ ] Criar modelo de dados de assinatura
- [ ] Implementar lógica de verificação de status
- [ ] Desenvolver banner de expiração
- [ ] Adicionar campo de expiração em novos usuários

### Fase 2: Integração Mercado Pago (3-4 dias)
- [ ] Configurar credenciais (teste e produção)
- [ ] Criar tela de assinatura
- [ ] Implementar criação de preferências
- [ ] Desenvolver processamento de webhooks
- [ ] Testar fluxo completo com cartões de teste

### Fase 3: Controle de Acesso (2-3 dias)
- [ ] Criar middleware de verificação
- [ ] Bloquear funcionalidades de escrita
- [ ] Implementar mensagens de erro
- [ ] Testar todos os cenários de bloqueio

### Fase 4: Exportação de Dados (2-3 dias)
- [ ] Implementar exportação de clientes
- [ ] Implementar exportação de produtos
- [ ] Implementar exportação de relatórios
- [ ] Otimizar para grandes volumes

### Fase 5: Ajustes Finais (1-2 dias)
- [ ] Ocultar vitrine das configurações
- [ ] Adicionar seção de suporte
- [ ] Testes end-to-end
- [ ] Deploy em produção

**Total**: 10-15 dias de desenvolvimento

## ⚠️ Riscos e Mitigações

| Risco | Mitigação |
|-------|-----------|
| Webhook falhar | Sistema de retry automático + verificação manual |
| Usuário manipular data | Validação sempre no servidor |
| Reclamações de bloqueio | Comunicação clara 5 dias antes |
| Problemas com exportação | Paginação e limites de dados |

## 💡 Diferenciais Competitivos

1. **Período Gratuito Generoso**: 2 meses completos sem cartão
2. **Exportação de Dados**: Usuários nunca perdem acesso aos seus dados
3. **Preços Acessíveis**: Planos pensados para pequenos comerciantes
4. **Suporte Direto**: WhatsApp e email do desenvolvedor
5. **Sem Surpresas**: Avisos claros antes da expiração

## 📈 Métricas de Sucesso

### Curto Prazo (3 meses)
- 50+ usuários ativos
- Taxa de conversão de 20% (gratuito → pago)
- Churn rate < 10%

### Médio Prazo (6 meses)
- 150+ usuários ativos
- Taxa de conversão de 30%
- Churn rate < 8%
- NPS > 50

### Longo Prazo (12 meses)
- 300+ usuários ativos
- Taxa de conversão de 40%
- Churn rate < 5%
- Receita recorrente > R$ 7.000/mês

## 🎓 Aprendizados Esperados

1. **Modelo SaaS**: Experiência com assinaturas recorrentes
2. **Integração de Pagamentos**: Domínio da API do Mercado Pago
3. **Webhooks**: Processamento assíncrono de eventos
4. **Controle de Acesso**: Implementação de permissões granulares
5. **Exportação de Dados**: Geração de arquivos Excel

## 📞 Próximos Passos Imediatos

1. ✅ **Você**: Acessar painel do Mercado Pago e copiar credenciais de teste
2. ⏳ **Desenvolvimento**: Começar implementação da Fase 1
3. ⏳ **Testes**: Validar fluxo com cartões de teste
4. ⏳ **Produção**: Ativar credenciais reais após testes

---

**Documentos Relacionados:**
- [Requisitos Completos](./requirements.md)
- [Guia Mercado Pago](./GUIA_MERCADO_PAGO.md)
- Design Técnico (a ser criado)
- Tasks de Implementação (a ser criado)

**Contato:**
- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074
