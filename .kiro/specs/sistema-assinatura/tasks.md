# Tasks: Sistema de Assinatura Bloquinho Digital

## Fase 1: Estrutura Base e Modelo de Dados

### 1.1 Configurar Credenciais do Mercado Pago
- [x] Adicionar credenciais no Firebase Functions Config
- [x] Criar arquivo `.env.example` com template
- [x] Adicionar `.env` no `.gitignore`
- [x] Documentar processo de configuração

### 1.2 Criar Modelo de Dados no Firestore
- [x] Criar estrutura de `subscription` no Firestore
- [x] Criar estrutura de `transactions` no Firestore
- [x] Criar estrutura de `webhooks` para logs
- [x] Atualizar regras de segurança do Firestore

### 1.3 Implementar Inicialização de Trial
- [x] Criar Firebase Function `initializeUserSubscription`
- [x] Adicionar 2 meses gratuitos para novos usuários
- [ ] Testar com criação de novo usuário
- [ ] Verificar dados salvos no Firestore

## Fase 2: Backend - Firebase Functions

### 2.1 Instalar Dependências
- [x] Instalar SDK do Mercado Pago no Functions
- [x] Configurar TypeScript se necessário
- [x] Atualizar `package.json` com dependências

### 2.2 Criar Função de Pagamento
- [x] Implementar `createPaymentPreference`
- [x] Validar autenticação do usuário
- [x] Validar plano selecionado
- [x] Criar preferência no Mercado Pago
- [x] Salvar transação pendente no Firestore
- [x] Retornar `init_point` para frontend
- [x] Adicionar tratamento de erros
- [ ] Testar com diferentes planos

### 2.3 Criar Webhook Handler
- [x] Implementar `mercadoPagoWebhook`
- [x] Validar assinatura do webhook
- [x] Salvar webhook em coleção de logs
- [x] Buscar detalhes do pagamento no Mercado Pago
- [x] Atualizar transação no Firestore
- [x] Chamar `updateSubscription` se aprovado
- [x] Adicionar retry logic para falhas
- [ ] Testar com webhooks de teste

### 2.4 Implementar Atualização de Assinatura
- [x] Criar função `updateSubscription`
- [x] Calcular nova data de expiração
- [x] Atualizar documento de subscription
- [x] Adicionar lógica para renovação vs nova assinatura
- [ ] Testar diferentes cenários

### 2.5 Criar Verificação Agendada
- [x] Implementar `checkSubscriptionStatus`
- [x] Agendar execução diária
- [x] Buscar assinaturas ativas
- [x] Atualizar status de expiradas
- [x] Adicionar logs de execução
- [ ] Testar agendamento

### 2.6 Deploy das Functions
- [ ] Fazer deploy das functions
- [ ] Verificar logs no Firebase Console
- [ ] Testar endpoints
- [ ] Configurar alertas de erro

## Fase 3: Frontend - Flutter

### 3.1 Criar Modelos de Dados
- [ ] Criar `SubscriptionModel`
- [ ] Criar `TransactionModel`
- [ ] Criar `PlanModel`
- [ ] Adicionar métodos `fromJson` e `toJson`

### 3.2 Criar Subscription Service
- [ ] Implementar `SubscriptionService`
- [ ] Método `checkStatus()`
- [ ] Método `createPaymentPreference()`
- [ ] Método `canAccess(feature)`
- [ ] Método `daysUntilExpiration()`
- [ ] Método `getCurrentSubscription()`
- [ ] Adicionar cache de status

### 3.3 Criar Tela de Assinatura
- [ ] Criar `SubscriptionScreen`
- [ ] Criar `PlanCard` widget
- [ ] Exibir 3 planos (mensal, trimestral, anual)
- [ ] Adicionar badge "Mais Popular" no trimestral
- [ ] Mostrar economia nos planos
- [ ] Implementar botão "Assinar"
- [ ] Adicionar loading state
- [ ] Redirecionar para Mercado Pago
- [ ] Criar FAQ section
- [ ] Tornar responsivo (mobile e desktop)

### 3.4 Criar Banner de Expiração
- [ ] Criar `SubscriptionBanner` widget
- [ ] Implementar `WarningBanner` (5 dias ou menos)
- [ ] Implementar `ExpiredBanner` (expirado)
- [ ] Adicionar botão "Renovar"
- [ ] Mostrar dias restantes
- [ ] Adicionar animação de entrada
- [ ] Tornar dismissible (apenas warning)

### 3.5 Integrar Banner no App
- [ ] Adicionar banner no `HomeShell` ou `DashboardScreen`
- [ ] Verificar status ao carregar app
- [ ] Atualizar banner em tempo real
- [ ] Testar diferentes estados

### 3.6 Criar Telas de Retorno de Pagamento
- [ ] Criar `PaymentSuccessScreen`
- [ ] Criar `PaymentFailureScreen`
- [ ] Criar `PaymentPendingScreen`
- [ ] Adicionar botões de navegação
- [ ] Verificar status da assinatura

## Fase 4: Controle de Acesso

### 4.1 Criar Middleware de Verificação
- [ ] Implementar `SubscriptionMiddleware`
- [ ] Método `checkAccess(action)`
- [ ] Identificar ações de escrita vs leitura
- [ ] Bloquear ações de escrita se expirado
- [ ] Mostrar modal explicativo

### 4.2 Integrar Middleware nas Funcionalidades
- [ ] Adicionar verificação em `addCustomer`
- [ ] Adicionar verificação em `addProduct`
- [ ] Adicionar verificação em `registerSale`
- [ ] Adicionar verificação em `addDebt`
- [ ] Adicionar verificação em `addLoan`
- [ ] Adicionar verificação em `addExpense`
- [ ] Testar bloqueio em cada funcionalidade

### 4.3 Criar Modal de Assinatura Expirada
- [ ] Criar `SubscriptionExpiredModal`
- [ ] Explicar que assinatura expirou
- [ ] Mostrar o que ainda pode fazer
- [ ] Botão "Renovar Agora"
- [ ] Botão "Exportar Dados"
- [ ] Tornar não-dismissible

## Fase 5: Exportação de Dados

### 5.1 Instalar Biblioteca Excel
- [ ] Adicionar `excel` package no `pubspec.yaml`
- [ ] Testar importação

### 5.2 Criar Export Service
- [ ] Implementar `ExportService`
- [ ] Método `exportCustomers()`
- [ ] Método `exportProducts()`
- [ ] Método `exportReports()`
- [ ] Adicionar formatação de células
- [ ] Adicionar cabeçalhos
- [ ] Implementar download do arquivo

### 5.3 Exportar Clientes
- [ ] Buscar todos os clientes do Firestore
- [ ] Criar planilha com colunas: Nome, Telefone, Status, Data
- [ ] Formatar dados
- [ ] Gerar arquivo Excel
- [ ] Iniciar download
- [ ] Testar com diferentes volumes

### 5.4 Exportar Produtos
- [ ] Buscar todos os produtos do Firestore
- [ ] Criar planilha com colunas: Nome, Categoria, Preço, Custo, Estoque, Margem
- [ ] Calcular margem de lucro
- [ ] Formatar valores monetários
- [ ] Gerar arquivo Excel
- [ ] Iniciar download
- [ ] Testar com diferentes volumes

### 5.5 Exportar Relatórios
- [ ] Permitir seleção de período
- [ ] Buscar dados do período
- [ ] Criar múltiplas abas: Vendas, Despesas, Resumo
- [ ] Adicionar gráficos (se possível)
- [ ] Formatar dados
- [ ] Gerar arquivo Excel
- [ ] Iniciar download
- [ ] Testar com diferentes períodos

### 5.6 Adicionar Botões de Exportação
- [ ] Adicionar botão em Clientes
- [ ] Adicionar botão em Produtos
- [ ] Adicionar botão em Relatórios
- [ ] Adicionar seção "Exportar Dados" nas Configurações
- [ ] Mostrar apenas se assinatura expirada (ou sempre disponível)

## Fase 6: Ajustes em Configurações

### 6.1 Remover/Ocultar Vitrine
- [ ] Localizar código da Vitrine em Settings
- [ ] Comentar ou remover seção
- [ ] Verificar se não quebra nada
- [ ] Testar navegação

### 6.2 Adicionar Seção de Suporte
- [ ] Criar `SupportSection` widget
- [ ] Adicionar email: tecnicorikardo@gmail.com
- [ ] Adicionar WhatsApp: (21) 97090-2074
- [ ] Botão para abrir WhatsApp
- [ ] Botão para enviar email
- [ ] Adicionar ícones apropriados

### 6.3 Adicionar Seção "Minha Assinatura"
- [ ] Criar `MySubscriptionSection` widget
- [ ] Mostrar plano atual
- [ ] Mostrar data de expiração
- [ ] Mostrar status (Ativa/Expirada/Expira em X dias)
- [ ] Botão "Gerenciar Assinatura"
- [ ] Redirecionar para `SubscriptionScreen`

### 6.4 Atualizar Settings Screen
- [ ] Integrar `SupportSection`
- [ ] Integrar `MySubscriptionSection`
- [ ] Reorganizar layout
- [ ] Testar navegação

## Fase 7: Testes e Validação

### 7.1 Testes de Pagamento
- [ ] Testar criação de preferência
- [ ] Testar redirecionamento para Mercado Pago
- [ ] Testar pagamento com cartão de teste aprovado
- [ ] Testar pagamento com cartão de teste rejeitado
- [ ] Verificar atualização de assinatura
- [ ] Verificar transação salva no Firestore

### 7.2 Testes de Webhook
- [ ] Simular webhook de pagamento aprovado
- [ ] Simular webhook de pagamento rejeitado
- [ ] Simular webhook de pagamento pendente
- [ ] Verificar logs de webhook
- [ ] Verificar atualização de subscription

### 7.3 Testes de Controle de Acesso
- [ ] Testar com assinatura ativa
- [ ] Testar com assinatura expirada
- [ ] Testar bloqueio de cada funcionalidade
- [ ] Testar modal de expiração
- [ ] Testar exportação de dados

### 7.4 Testes de Banner
- [ ] Testar banner com 5 dias restantes
- [ ] Testar banner com 1 dia restante
- [ ] Testar banner com assinatura expirada
- [ ] Testar botão de renovação
- [ ] Testar dismiss do warning banner

### 7.5 Testes de Exportação
- [ ] Testar exportação de clientes vazio
- [ ] Testar exportação de clientes com dados
- [ ] Testar exportação de produtos vazio
- [ ] Testar exportação de produtos com dados
- [ ] Testar exportação de relatórios
- [ ] Verificar formato do Excel
- [ ] Verificar download do arquivo

### 7.6 Testes de Novos Usuários
- [ ] Criar novo usuário
- [ ] Verificar trial de 2 meses criado
- [ ] Verificar acesso completo
- [ ] Verificar data de expiração correta

### 7.7 Testes End-to-End
- [ ] Fluxo completo: Cadastro → Trial → Expiração → Renovação
- [ ] Fluxo de exportação com assinatura expirada
- [ ] Fluxo de múltiplas renovações
- [ ] Fluxo de diferentes planos

## Fase 8: Deploy e Monitoramento

### 8.1 Preparar para Produção
- [ ] Revisar todas as credenciais
- [ ] Verificar URLs de produção
- [ ] Atualizar variáveis de ambiente
- [ ] Revisar regras de segurança do Firestore

### 8.2 Deploy
- [ ] Deploy das Firebase Functions
- [ ] Deploy do Flutter Web
- [ ] Verificar logs
- [ ] Testar em produção

### 8.3 Configurar Monitoramento
- [ ] Configurar alertas de erro no Firebase
- [ ] Configurar alertas de webhook falhando
- [ ] Configurar dashboard de métricas
- [ ] Documentar processo de troubleshooting

### 8.4 Documentação
- [ ] Atualizar README com informações de assinatura
- [ ] Documentar processo de renovação manual
- [ ] Documentar processo de reembolso
- [ ] Criar guia para usuários

## Fase 9: Melhorias Futuras (Opcional)

### 9.1 Notificações por Email
- [ ] Configurar SendGrid ou similar
- [ ] Email de boas-vindas com trial
- [ ] Email 7 dias antes da expiração
- [ ] Email 3 dias antes da expiração
- [ ] Email de confirmação de pagamento
- [ ] Email de falha de pagamento

### 9.2 Dashboard Admin
- [ ] Criar painel administrativo
- [ ] Visualizar todas as assinaturas
- [ ] Visualizar transações
- [ ] Métricas de conversão
- [ ] Gráficos de receita

### 9.3 Cupons de Desconto
- [ ] Sistema de cupons
- [ ] Validação de cupons
- [ ] Aplicar desconto no pagamento
- [ ] Rastrear uso de cupons

### 9.4 Programa de Afiliados
- [ ] Sistema de referência
- [ ] Rastrear indicações
- [ ] Comissões para afiliados
- [ ] Dashboard de afiliados

---

## Resumo de Progresso

**Total de Tasks**: 150+
**Estimativa de Tempo**: 10-15 dias

### Por Fase:
- Fase 1: 2-3 dias
- Fase 2: 3-4 dias
- Fase 3: 2-3 dias
- Fase 4: 2-3 dias
- Fase 5: 2-3 dias
- Fase 6: 1 dia
- Fase 7: 2 dias
- Fase 8: 1 dia

**Prioridade Alta**: Fases 1-6
**Prioridade Média**: Fases 7-8
**Prioridade Baixa**: Fase 9 (melhorias futuras)
