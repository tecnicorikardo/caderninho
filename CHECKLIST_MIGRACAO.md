# ✅ Checklist de Migração para Appwrite

Use este checklist para acompanhar o progresso da migração.

## 📋 Fase 1: Preparação

- [ ] Ler documentação completa (`MIGRACAO_APPWRITE.md`)
- [ ] Ler guia rápido (`INICIO_RAPIDO_APPWRITE.md`)
- [ ] Entender a arquitetura da camada de abstração
- [ ] Fazer backup completo do Firebase
- [ ] Documentar estado atual do sistema

## 🏗️ Fase 2: Setup do Appwrite

### Criar Projeto
- [ ] Criar conta no Appwrite Cloud (ou instalar self-hosted)
- [ ] Criar novo projeto "Bloquinho Digital"
- [ ] Anotar Project ID
- [ ] Anotar Endpoint URL

### Criar API Key
- [ ] Acessar Settings → API Keys
- [ ] Criar nova API Key "Migration Script"
- [ ] Selecionar scopes de `databases.*`
- [ ] Copiar e guardar API Key em local seguro

### Configurar Variáveis de Ambiente
- [ ] Copiar `.env.example` para `.env`
- [ ] Preencher `APPWRITE_ENDPOINT`
- [ ] Preencher `APPWRITE_PROJECT_ID`
- [ ] Preencher `APPWRITE_API_KEY`
- [ ] Preencher `APPWRITE_DATABASE_ID`

## 🗄️ Fase 3: Criar Database e Collections

### Instalar Dependências
- [ ] `cd tools`
- [ ] `npm install`

### Executar Setup Automático
- [ ] `npm run setup`
- [ ] Verificar que database foi criado
- [ ] Verificar que 6 collections foram criadas
- [ ] Verificar atributos de cada collection
- [ ] Verificar índices de cada collection

### Verificação Manual (Opcional)
- [ ] Acessar console do Appwrite
- [ ] Navegar até Databases → bloquinho
- [ ] Verificar collection `users_profiles`
- [ ] Verificar collection `customers`
- [ ] Verificar collection `inventory_items`
- [ ] Verificar collection `sales`
- [ ] Verificar collection `receivables`
- [ ] Verificar collection `inventory_movements`

## 📦 Fase 4: Migração de Dados

### Preparação
- [ ] Verificar que arquivo de credenciais Firebase existe
- [ ] Confirmar que collections foram criadas
- [ ] Fazer backup adicional (segurança)

### Executar Migração
- [ ] `npm run migrate`
- [ ] Acompanhar progresso no terminal
- [ ] Verificar estatísticas de sucesso/erro
- [ ] Anotar quantidade de documentos migrados

### Verificação
- [ ] Verificar dados em `users_profiles`
- [ ] Verificar dados em `customers`
- [ ] Verificar dados em `inventory_items`
- [ ] Verificar dados em `sales`
- [ ] Verificar dados em `receivables`
- [ ] Verificar dados em `inventory_movements`
- [ ] Comparar contagens com Firebase

## ⚙️ Fase 5: Configurar Aplicação

### Variáveis de Ambiente Web
- [ ] Copiar `web/.env.example` para `web/.env.local`
- [ ] Preencher `VITE_APPWRITE_ENDPOINT`
- [ ] Preencher `VITE_APPWRITE_PROJECT_ID`
- [ ] Preencher `VITE_APPWRITE_DATABASE_ID`
- [ ] Preencher IDs das collections
- [ ] Definir `VITE_DB_PROVIDER=appwrite`

### Instalar Dependências
- [ ] `cd web`
- [ ] `npm install` (appwrite já foi instalado)

## 🧪 Fase 6: Testes

### Testes de Autenticação
- [ ] Criar nova conta
- [ ] Fazer login com conta existente
- [ ] Fazer logout
- [ ] Recuperar senha
- [ ] Verificar sessão persistente

### Testes de Clientes
- [ ] Listar clientes
- [ ] Buscar cliente por nome
- [ ] Criar novo cliente
- [ ] Editar cliente
- [ ] Excluir cliente
- [ ] Verificar histórico do cliente

### Testes de Estoque
- [ ] Listar produtos
- [ ] Buscar produto
- [ ] Criar novo produto
- [ ] Editar produto
- [ ] Excluir produto
- [ ] Registrar entrada de estoque
- [ ] Registrar saída de estoque
- [ ] Verificar movimentações

### Testes de Vendas
- [ ] Criar venda à vista
- [ ] Criar venda fiado
- [ ] Criar venda com produto
- [ ] Verificar baixa de estoque
- [ ] Verificar criação de recebível
- [ ] Listar vendas do dia
- [ ] Filtrar vendas por período

### Testes de Recebíveis
- [ ] Listar recebíveis
- [ ] Filtrar por status
- [ ] Filtrar por cliente
- [ ] Registrar pagamento parcial
- [ ] Registrar pagamento total
- [ ] Verificar atualização de status

### Testes de Relatórios
- [ ] Dashboard do dia
- [ ] Relatório semanal
- [ ] Relatório mensal
- [ ] Comissões por marca
- [ ] Produtos mais vendidos
- [ ] Melhores clientes

### Testes de Performance
- [ ] Tempo de carregamento inicial
- [ ] Tempo de listagem de clientes
- [ ] Tempo de listagem de produtos
- [ ] Tempo de criação de venda
- [ ] Tempo de geração de relatórios

## 🔒 Fase 7: Segurança

### Permissões
- [ ] Verificar Document Security habilitado
- [ ] Testar isolamento entre usuários
- [ ] Verificar que usuário A não vê dados de usuário B
- [ ] Testar permissões de leitura
- [ ] Testar permissões de escrita
- [ ] Testar permissões de exclusão

### Validação
- [ ] Testar campos obrigatórios
- [ ] Testar limites de tamanho
- [ ] Testar tipos de dados
- [ ] Testar valores inválidos

## 📊 Fase 8: Monitoramento

### Configurar Monitoramento
- [ ] Configurar alertas de uso
- [ ] Configurar alertas de erro
- [ ] Configurar backup automático
- [ ] Documentar métricas baseline

### Métricas Iniciais
- [ ] Número de usuários migrados: _____
- [ ] Número de clientes migrados: _____
- [ ] Número de produtos migrados: _____
- [ ] Número de vendas migradas: _____
- [ ] Número de recebíveis migrados: _____
- [ ] Tamanho total do database: _____

## 🚀 Fase 9: Deploy

### Preparação
- [ ] Testar build de produção
- [ ] Verificar variáveis de ambiente de produção
- [ ] Preparar plano de rollback
- [ ] Comunicar usuários sobre manutenção

### Deploy
- [ ] Fazer deploy da nova versão
- [ ] Verificar que aplicação está online
- [ ] Testar funcionalidades críticas
- [ ] Monitorar logs de erro
- [ ] Monitorar performance

### Pós-Deploy
- [ ] Verificar que usuários conseguem acessar
- [ ] Monitorar erros nas primeiras horas
- [ ] Coletar feedback dos usuários
- [ ] Documentar problemas encontrados

## 🔄 Fase 10: Transição

### Período de Transição (30 dias)
- [ ] Manter Firebase ativo
- [ ] Monitorar uso do Appwrite
- [ ] Coletar feedback contínuo
- [ ] Resolver problemas identificados
- [ ] Otimizar queries lentas

### Desativação do Firebase
- [ ] Confirmar que tudo está funcionando
- [ ] Fazer backup final do Firebase
- [ ] Desativar Firebase Auth
- [ ] Desativar Firestore
- [ ] Cancelar plano Firebase (se aplicável)

## 📝 Fase 11: Documentação

### Atualizar Documentação
- [ ] Atualizar README.md
- [ ] Atualizar guias de desenvolvimento
- [ ] Documentar mudanças na arquitetura
- [ ] Criar guia de troubleshooting
- [ ] Documentar lições aprendidas

### Compartilhar Conhecimento
- [ ] Treinar equipe (se aplicável)
- [ ] Criar vídeos tutoriais (opcional)
- [ ] Documentar melhores práticas
- [ ] Criar FAQ

## ✅ Conclusão

### Checklist Final
- [ ] Todos os dados migrados
- [ ] Todas as funcionalidades testadas
- [ ] Performance aceitável
- [ ] Segurança validada
- [ ] Monitoramento configurado
- [ ] Deploy realizado com sucesso
- [ ] Documentação atualizada
- [ ] Equipe treinada
- [ ] Firebase desativado
- [ ] Usuários satisfeitos

### Métricas de Sucesso
- [ ] 100% dos dados migrados
- [ ] 0 erros críticos
- [ ] Performance igual ou melhor
- [ ] Custos reduzidos
- [ ] Usuários satisfeitos

---

## 📊 Estatísticas da Migração

**Data de Início:** ___/___/______

**Data de Conclusão:** ___/___/______

**Tempo Total:** _____ dias

**Dados Migrados:**
- Usuários: _____
- Clientes: _____
- Produtos: _____
- Vendas: _____
- Recebíveis: _____

**Problemas Encontrados:** _____

**Tempo de Downtime:** _____

**Satisfação dos Usuários:** ⭐⭐⭐⭐⭐

---

## 🎉 Parabéns!

Se você chegou até aqui e marcou todos os itens, a migração foi um sucesso! 🚀

**Próximos passos:**
1. Continuar monitorando
2. Otimizar performance
3. Coletar feedback
4. Implementar melhorias
5. Considerar self-hosted (futuro)

**Recursos:**
- [Documentação Appwrite](https://appwrite.io/docs)
- [Discord Appwrite](https://appwrite.io/discord)
- [GitHub Issues](https://github.com/appwrite/appwrite/issues)
