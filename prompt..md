Você é um Arquiteto/Tech Lead e Product Designer Sênior. Crie a especificação + arquitetura + backlog + modelo de dados + fluxos de telas para um aplicativo chamado “Gestor Comercial” voltado a pequenos comerciantes.

STACK / PLATAFORMAS
- Flutter (mobile Android/iOS) + acesso via Web (Flutter Web).
- Firebase: Authentication (email/senha), Firestore, Storage (se precisar), Cloud Functions (se necessário), Hosting.
- Offline-first: o app deve funcionar sem internet e sincronizar depois (Firestore cache + estratégia de filas).
- Foco em layout profissional (UI moderna, responsiva e consistente no mobile e web).

AUTENTICAÇÃO
- Login com Email e Senha (Firebase Auth).
- “Esqueci minha senha” (reset por email).
- “Lembrar e-mail” (persistência local segura).
- Tela de login/cadastro com aparência profissional.

NAVEGAÇÃO / HOME
- Tela principal (Dashboard do dia).
- Um botão fixo (FAB) sempre visível.
- Ao tocar no botão fixo, abrir um MODAL com o resumo do que foi feito NO DIA (cards/contadores):
  - Vendas do dia (quantidade + total)
  - Fiados do dia (quantidade + total em aberto)
  - Financeiro do dia (receitas, despesas, saldo do dia)
  - Atalhos rápidos (Nova venda, Novo fiado, Novo cliente, Novo produto, Novo empréstimo, Registrar pagamento)
- Regra: ao mudar de dia, o “painel do dia” zera (ou seja, os indicadores “do dia” voltam a 0), mas os dados históricos continuam salvos. O sistema deve calcular “do dia” por data (não apagando dados).

MÓDULO: VENDAS
- Suportar 2 modos:
  1) Venda com produtos (seleciona itens do estoque, quantidades, descontos opcionais).
  2) Venda livre (sem produto): usuário digita descrição e valor.
- Ao finalizar venda, mostrar MODAL final com opções:
  - Imprimir recibo (web: imprimir; mobile: gerar PDF/compartilhar)
  - Compartilhar via WhatsApp (texto formatado + opcional PDF)
  - Finalizar e voltar para Tela principal
- Registrar data/hora, método de pagamento (dinheiro/pix/cartão/outros), cliente opcional, itens, totais, lucro estimado (se houver custo).
- Se venda com produtos: baixar estoque automaticamente.

MÓDULO: EMPRÉSTIMOS
- Fluxo:
  1) Escolher cliente
  2) Informar valor emprestado
  3) Informar data de término/vencimento
  4) Aplicar juros após o vencimento (definir regra de juros: percentual ao mês ou ao dia; implementar como configurável)
- Empréstimos entram também em “devedores/fiados” (dívida total do cliente deve somar fiados + empréstimos).
- Permitir pagamentos parciais e registrar histórico.

MÓDULO: CLIENTES
- CRUD: criar/editar/excluir cliente.
- Campo de busca por nome/telefone.
- Importar e exportar via Excel (XLSX/CSV) com mapeamento de colunas.
- Cada cliente tem histórico de compras e dívidas.
- Compartilhar via WhatsApp o histórico de compras (com datas, valores, e status pago/fiado).
- Regras: ao excluir cliente, definir política (bloquear exclusão se houver dívidas / ou manter registros e marcar como inativo).

MÓDULO: PRODUTOS / ESTOQUE
- CRUD: criar/editar/excluir.
- Importar/exportar via Excel (XLSX/CSV).
- Produtos organizados por categoria.
- Cada produto tem: nome, categoria, preço de venda, custo, estoque atual, unidade (un/ kg/ lt), código opcional, status ativo.
- Regra importante (entendimento do requisito do usuário):
  - Cada CATEGORIA pode ter “campos específicos” próprios (atributos extras). Ex.: 
    - Categoria “Roupas”: tamanho, cor, marca
    - Categoria “Bebidas”: ml, validade, fornecedor
    - Categoria “Eletrônicos”: garantia, voltagem
  - Implementar isso como “atributos dinâmicos por categoria” (schema flexível) e UI que muda os campos ao escolher a categoria.
  - Explique claramente como vai modelar isso no Firestore e no app (ex.: template de campos por categoria + valores por produto).

MÓDULO: FIADOS (DEVEDORES)
- Lista com todos os devedores (incluindo empréstimos).
- Mostrar total em aberto por cliente e detalhamento.
- Permitir “pagar parcialmente” qualquer valor (abater do total e registrar pagamento).
- Compartilhar via WhatsApp o histórico do devedor (itens/parcelas, pagamentos, saldo).

MÓDULO: FINANCEIRO
- Regra: ao adicionar/atualizar produto com custo (entrada de estoque), isso gera automaticamente uma DESPESA (ex.: “Compra de estoque”).
- Regra: vendas geram RECEITA automaticamente.
- Permitir registrar despesas avulsas e receitas avulsas (opcional, mas recomendado).
- Tela financeiro com visão: receitas, despesas, saldo, por dia/semana/mês.

MÓDULO: RELATÓRIOS
- Tudo detalhado e com filtros:
  - Vendas de hoje
  - Vendas da semana
  - Vendas por mês (mês a mês)
  - Melhor cliente (por valor total e por frequência)
  - Produto mais vendido (quantidade e valor)
  - Lucro estimado (com base no custo do produto)
- Exportar relatórios em PDF e/ou Excel.

IA OFFLINE
- Criar uma “IA offline” simples para insights locais, sem depender de nuvem:
  - Sugestões com base em regras + estatísticas locais (ex.: “seu produto mais vendido hoje foi X”, “clientes com maior recorrência”, “alerta de estoque baixo”, “pico de vendas por horário”).
  - Não usar API externa. Tudo calculado localmente.
  - Se sugerir ML on-device, manter opcional; priorizar heurísticas/statistics.

REQUISITOS NÃO FUNCIONAIS
- UX profissional: componentes consistentes, tema, tipografia, ícones, dark mode opcional.
- Segurança:
  - Firestore Security Rules por usuário (multi-tenant): cada usuário só acessa seus dados.
- Performance:
  - Paginação em listas, índices no Firestore.
- Observabilidade:
  - Logging básico (crashlytics se quiser) e rastreio de eventos essenciais.

ENTREGÁVEIS (o que você deve me devolver)
1) Perguntas de validação (máximo 10) somente se forem essenciais — caso contrário, assuma defaults razoáveis.
2) Lista completa de telas (mobile e web) + navegação.
3) Fluxos detalhados (venda, fiado, empréstimo, importar/exportar, pagamentos).
4) Modelo de dados Firestore (coleções, documentos, subcoleções) incluindo:
   - Users/Store
   - Clientes
   - Produtos
   - Categorias + templates de campos dinâmicos
   - Vendas + itens
   - Fiados/Dividas
   - Empréstimos
   - Pagamentos
   - Financeiro (lançamentos)
5) Regras de negócio explícitas (cálculos, datas, juros, status).
6) Segurança (Firestore Rules em pseudo-código + estratégia de índices).
7) Backlog (MVP → V1 → V2) com prioridades e critérios de aceite.
8) Sugestão de bibliotecas Flutter (state management, routing, pdf/print, excel import/export, whatsapp share).
9) Estrutura de pastas Flutter (clean architecture) e padrões.
10) Plano offline-first e sincronização (conflitos, timestamps, versionamento).

Padrões que você deve seguir
- Seja objetivo e implementável.
- Sempre que definir algo, inclua exemplo (ex.: exemplo de documento Firestore, exemplo de payload de recibo WhatsApp).
- Assuma Brasil: moeda BRL, datas dd/MM/yyyy, suporte a Pix.