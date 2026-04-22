# Status do Projeto - Gestor Comercial

Atualizado em: 2026-02-22

## Ja foi feito

- Base Flutter criada e funcionando em Web/Chrome.
- Tema visual inicial profissional e navegacao principal.
- Dashboard do dia com FAB e modal de resumo.
- Modulo de vendas com:
  - venda livre e venda com produto
  - escolha de cliente opcional
  - escolha de produto opcional
  - forma de pagamento incluindo fiado
  - regra: venda fiado cria divida e abre tela de fiados
- Busca inteligente de clientes na venda e na tela de clientes.
- Modulo de clientes:
  - cadastro de cliente
  - busca por nome/telefone
  - historico do cliente (vendas, fiados, emprestimos)
  - compartilhamento no WhatsApp (com numero do cliente se existir)
  - editar cliente
  - excluir com politica: se tiver pendencia em aberto, inativa; sem pendencia, exclui
  - reativar cliente inativo
- Modulo de produtos/estoque:
  - cadastro de produto
  - baixa de estoque automatica na venda com produto
  - editar/excluir produto
  - ao excluir, baixa automatica do estoque com motivo
  - movimentacao manual de estoque (entrada e baixa) com motivo
  - sincronizacao com financeiro em ajustes/exclusao (lancamento de despesa)
- Modulo de fiados:
  - cadastro de divida
  - pagamento parcial
- Modulo de emprestimos:
  - cadastro com vencimento e juros (dia/mes)
  - pagamento parcial
- Modulo financeiro:
  - receita automatica em venda paga
  - despesa automatica em entrada de estoque (custo x estoque)
  - visao por dia/semana/mes
- Persistencia no Firebase:
  - Firebase inicializado no app
  - Firebase Auth (email/senha) integrado
  - Firestore integrado para salvar e ler dados reais
  - dados por usuario em `users/{uid}/...`
- Orientacao de planilha (modelo) em Clientes e Produtos.
- Build e validacao tecnica recentes:
  - `flutter analyze` OK
  - `flutter test` OK
  - `flutter build web` OK

## Falta fazer

### Autenticacao e conta

- Fluxo completo de logout na UI.
- Revisar UX de cadastro/login/reset (mensagens, estados e erros).

### Clientes

- Importacao real CSV/XLSX e exportacao.

### Produtos/Estoque

- Importacao real CSV/XLSX e exportacao.
- Categorias com atributos dinamicos (template por categoria).

### Vendas

- Itens com desconto por item e total final detalhado.
- Lucro estimado por venda com base no custo.
- Modal final de venda com:
  - imprimir recibo
  - gerar/compartilhar PDF
  - compartilhar texto/recibo no WhatsApp

### Fiados e emprestimos

- Historico detalhado de pagamentos por registro.
- Visao consolidada de devedores por cliente (fiado + emprestimo) com melhor detalhamento.
- Listagem consolidada de clientes devedores.

### Relatorios

- Tela de relatorios completa com filtros:
  - hoje/semana/mes
  - melhor cliente (valor e frequencia)
  - produto mais vendido
  - lucro estimado
- Exportacao de relatorios em PDF/Excel.

### Offline-first e sincronizacao

- Estrategia explicita de conflitos e versionamento.
- Fila de operacoes offline com feedback claro de sincronizacao.

### Seguranca e producao

- Endurecer Firestore Rules por schema/campos obrigatorios.
- Revisar indices para consultas de relatorio.
- Revisar colecoes/estrutura final para escala.

### Observabilidade

- Logging estruturado de eventos principais.
- Opcional: Crashlytics e trilha de auditoria.

## Proxima prioridade recomendada

1. Importacao real de clientes/produtos (CSV/XLSX) com validacao por linha.
2. Relatorios com filtros e lucro estimado.
3. Recibo/WhatsApp/PDF ao finalizar venda.
4. Historico detalhado de pagamentos e visao consolidada de devedores.
