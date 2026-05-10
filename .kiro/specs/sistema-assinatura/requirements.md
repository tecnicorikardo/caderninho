# Requisitos: Sistema de Assinatura e Monetização

## 1. Visão Geral

Transformar o Bloquinho Digital em um sistema SaaS (Software as a Service) com modelo de assinatura paga, integrando pagamentos via Mercado Pago e implementando controle de acesso baseado no status da assinatura.

## 2. Objetivos de Negócio

- Monetizar o aplicativo através de assinaturas mensais e anuais
- Oferecer período de teste gratuito de 2 meses para novos usuários
- Automatizar completamente o processo de pagamento e liberação de acesso
- Garantir que usuários inadimplentes tenham acesso limitado (apenas exportação de dados)
- Facilitar o suporte ao cliente com informações de contato visíveis

## 3. Stakeholders

- **Proprietário do Sistema**: Ricardo (tecnicorikardo@gmail.com / WhatsApp: 21970902074)
- **Usuários Finais**: Pequenos comerciantes que usam o sistema
- **Processador de Pagamentos**: Mercado Pago

## 4. Requisitos Funcionais

### 4.1 Planos de Assinatura

**RF-001**: O sistema deve oferecer 3 planos de assinatura:
- **Mensal**: R$ 29,90 por mês
- **Trimestral**: R$ 49,90 por 3 meses (economia de ~44%)
- **Anual**: R$ 299,90 por 12 meses (economia de ~16%)

**RF-002**: Todos os novos usuários devem receber automaticamente 2 meses de acesso gratuito ao se cadastrarem.

**RF-003**: O período gratuito deve começar a contar a partir da data de criação da conta do usuário.

### 4.2 Controle de Acesso

**RF-004**: Usuários com assinatura ativa (gratuita ou paga) devem ter acesso completo a todas as funcionalidades do sistema.

**RF-005**: Usuários com assinatura expirada devem ter acesso APENAS às seguintes funcionalidades:
- Exportação de clientes para Excel
- Exportação de produtos para Excel
- Exportação de relatórios para Excel
- Visualização de dados existentes (somente leitura)

**RF-006**: Usuários com assinatura expirada NÃO devem poder:
- Adicionar novos clientes
- Adicionar novos produtos
- Registrar vendas
- Adicionar fiados ou empréstimos
- Adicionar despesas
- Modificar dados existentes

### 4.3 Notificações de Expiração

**RF-007**: O sistema deve exibir um banner de aviso no topo da tela quando faltarem 5 dias ou menos para a expiração da assinatura.

**RF-008**: O banner deve mostrar:
- Quantidade de dias restantes
- Botão para renovar assinatura
- Mensagem clara sobre o que acontecerá após expiração

**RF-009**: Após a expiração, o sistema deve exibir um banner permanente informando que a assinatura expirou e oferecendo opção de renovação.

### 4.4 Integração com Mercado Pago

**RF-010**: O sistema deve integrar com a API do Mercado Pago para processar pagamentos.

**RF-011**: Ao clicar em "Assinar" ou "Renovar", o usuário deve ser redirecionado para a página de pagamento do Mercado Pago.

**RF-012**: O sistema deve criar uma preferência de pagamento no Mercado Pago contendo:
- Descrição do plano escolhido
- Valor do plano
- ID do usuário (para identificação)
- URLs de retorno (sucesso, falha, pendente)

**RF-013**: O sistema deve receber webhooks do Mercado Pago para atualizar automaticamente o status da assinatura quando:
- Pagamento for aprovado
- Pagamento for rejeitado
- Pagamento estiver pendente

**RF-014**: Quando um pagamento for aprovado, o sistema deve:
- Adicionar o período correspondente ao plano à data de expiração do usuário
- Registrar a transação no histórico
- Enviar email de confirmação (opcional)

### 4.5 Exportação de Dados

**RF-015**: Usuários com assinatura expirada devem poder exportar seus dados em formato Excel (.xlsx).

**RF-016**: A exportação de clientes deve incluir:
- Nome
- Telefone
- Status (ativo/inativo)
- Data de cadastro

**RF-017**: A exportação de produtos deve incluir:
- Nome
- Categoria
- Preço de venda
- Custo
- Estoque atual
- Unidade
- Margem de lucro

**RF-018**: A exportação de relatórios deve incluir dados do período selecionado:
- Vendas (data, descrição, valor, forma de pagamento)
- Receitas e despesas
- Lucro líquido
- Métricas principais

### 4.6 Configurações e Suporte

**RF-019**: A seção de Vitrine deve ser removida/ocultada das configurações.

**RF-020**: As configurações devem exibir uma seção "Suporte" com:
- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074
- Botão para abrir WhatsApp diretamente
- Botão para enviar email

**RF-021**: As configurações devem exibir uma seção "Minha Assinatura" mostrando:
- Plano atual (Gratuito/Mensal/Trimestral/Anual)
- Data de expiração
- Status (Ativa/Expirada/Expira em X dias)
- Botão para gerenciar assinatura

### 4.7 Tela de Assinatura

**RF-022**: Deve existir uma tela dedicada para escolha e contratação de planos.

**RF-023**: A tela deve mostrar os 3 planos lado a lado (em desktop) ou empilhados (em mobile).

**RF-024**: Cada card de plano deve mostrar:
- Nome do plano
- Preço
- Economia (se aplicável)
- Período de cobertura
- Botão "Assinar"
- Badge "Mais Popular" no plano trimestral

**RF-025**: Deve haver um FAQ na tela de assinatura respondendo:
- Como funciona o período gratuito?
- Posso cancelar a qualquer momento?
- O que acontece se eu não renovar?
- Como faço para exportar meus dados?

## 5. Requisitos Não-Funcionais

### 5.1 Segurança

**RNF-001**: As credenciais do Mercado Pago devem ser armazenadas de forma segura (variáveis de ambiente ou Firebase Functions Config).

**RNF-002**: A validação de webhooks do Mercado Pago deve verificar a assinatura para garantir autenticidade.

**RNF-003**: Dados de pagamento nunca devem ser armazenados no sistema (PCI compliance).

### 5.2 Performance

**RNF-004**: A verificação de status da assinatura deve ser feita no lado do servidor (Firebase Functions) para evitar manipulação.

**RNF-005**: O banner de expiração deve ser carregado de forma assíncrona para não impactar a performance.

**RNF-006**: A exportação de dados deve ser otimizada para não travar a interface em grandes volumes.

### 5.3 Usabilidade

**RNF-007**: O processo de assinatura deve ter no máximo 3 cliques do usuário.

**RNF-008**: Mensagens de erro de pagamento devem ser claras e orientar o usuário sobre próximos passos.

**RNF-009**: A interface deve ser responsiva e funcionar bem em mobile e desktop.

### 5.4 Confiabilidade

**RNF-010**: O sistema deve ter um mecanismo de retry para webhooks que falharem.

**RNF-011**: Deve haver logs detalhados de todas as transações de pagamento.

**RNF-012**: Em caso de falha na verificação de assinatura, o sistema deve permitir acesso temporário e notificar o administrador.

## 6. Regras de Negócio

**RN-001**: O período gratuito de 2 meses é concedido apenas uma vez por usuário (baseado no email/UID).

**RN-002**: Ao renovar uma assinatura antes da expiração, o novo período é adicionado à data de expiração atual (não sobrescreve).

**RN-003**: Ao renovar uma assinatura após expiração, o novo período começa a partir da data de pagamento.

**RN-004**: Não há reembolso automático. Casos de reembolso devem ser tratados manualmente pelo suporte.

**RN-005**: Usuários podem fazer upgrade de plano a qualquer momento (diferença proporcional é calculada).

**RN-006**: Downgrade de plano só é permitido após o término do período atual.

**RN-007**: Dados de usuários inativos (mais de 6 meses sem assinatura) podem ser arquivados mas não deletados.

## 7. Casos de Uso Principais

### UC-001: Novo Usuário se Cadastra
1. Usuário cria conta no sistema
2. Sistema automaticamente concede 2 meses gratuitos
3. Sistema define data de expiração como hoje + 60 dias
4. Usuário tem acesso completo ao sistema

### UC-002: Usuário Assina um Plano
1. Usuário acessa tela de assinatura
2. Usuário escolhe um plano (mensal/trimestral/anual)
3. Sistema redireciona para Mercado Pago
4. Usuário completa pagamento
5. Mercado Pago envia webhook de confirmação
6. Sistema atualiza data de expiração
7. Usuário recebe confirmação

### UC-003: Assinatura Está Próxima de Expirar
1. Sistema verifica diariamente assinaturas
2. Se faltam 5 dias ou menos, exibe banner
3. Banner mostra dias restantes e botão de renovação
4. Usuário pode clicar para renovar ou ignorar

### UC-004: Assinatura Expirou
1. Sistema detecta que data de expiração passou
2. Sistema bloqueia funcionalidades de escrita
3. Sistema exibe banner de expiração
4. Usuário só pode visualizar e exportar dados
5. Usuário pode clicar em "Renovar" para reativar

### UC-005: Usuário Exporta Dados
1. Usuário com assinatura expirada acessa configurações
2. Usuário clica em "Exportar Dados"
3. Sistema gera arquivo Excel com dados
4. Sistema inicia download do arquivo

## 8. Critérios de Aceitação

- [ ] Novos usuários recebem automaticamente 2 meses gratuitos
- [ ] Banner de expiração aparece 5 dias antes do vencimento
- [ ] Usuários com assinatura expirada não conseguem adicionar/editar dados
- [ ] Usuários com assinatura expirada conseguem exportar dados para Excel
- [ ] Integração com Mercado Pago funciona corretamente
- [ ] Webhooks do Mercado Pago atualizam status automaticamente
- [ ] Tela de assinatura mostra os 3 planos claramente
- [ ] Seção de suporte mostra email e WhatsApp corretos
- [ ] Vitrine está oculta das configurações
- [ ] Sistema registra todas as transações no Firestore

## 9. Dependências

- **Mercado Pago SDK**: Para integração de pagamentos
- **Excel Export Library**: Para geração de arquivos .xlsx (ex: xlsx ou excel4node)
- **Firebase Functions**: Para processar webhooks e validações server-side
- **Firebase Firestore**: Para armazenar dados de assinaturas e transações

## 10. Riscos e Mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| Webhook do Mercado Pago falhar | Alto | Média | Implementar retry automático e verificação manual |
| Usuário manipular data de expiração no cliente | Alto | Baixa | Validar sempre no servidor (Firebase Functions) |
| Problemas com exportação de grandes volumes | Médio | Média | Implementar paginação e limites |
| Credenciais do Mercado Pago vazarem | Alto | Baixa | Usar variáveis de ambiente e nunca commitar no código |
| Usuários reclamarem de bloqueio | Médio | Alta | Comunicação clara e antecipada sobre expiração |

## 11. Cronograma Estimado

1. **Fase 1 - Estrutura Base** (2-3 dias)
   - Modelo de dados de assinatura
   - Lógica de verificação de status
   - Banner de expiração

2. **Fase 2 - Integração Mercado Pago** (3-4 dias)
   - Configuração de credenciais
   - Criação de preferências de pagamento
   - Processamento de webhooks
   - Tela de assinatura

3. **Fase 3 - Controle de Acesso** (2-3 dias)
   - Bloqueio de funcionalidades
   - Middleware de verificação
   - Mensagens de erro apropriadas

4. **Fase 4 - Exportação de Dados** (2-3 dias)
   - Exportação de clientes
   - Exportação de produtos
   - Exportação de relatórios

5. **Fase 5 - Ajustes Finais** (1-2 dias)
   - Remover/ocultar vitrine
   - Adicionar seção de suporte
   - Testes end-to-end
   - Deploy

**Total Estimado**: 10-15 dias de desenvolvimento

## 12. Próximos Passos

1. Obter credenciais do Mercado Pago (Access Token e Public Key)
2. Criar documento de design técnico
3. Implementar modelo de dados
4. Desenvolver integração com Mercado Pago
5. Implementar controle de acesso
6. Desenvolver funcionalidade de exportação
7. Testar fluxo completo
8. Deploy em produção
