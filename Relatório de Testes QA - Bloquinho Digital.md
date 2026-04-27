# Relatório de Testes QA - Bloquinho Digital

## 1. Autenticação e Onboarding
- **Login com credenciais inválidas**: OK (Mostrou erro de Firebase).
- **Login com credenciais válidas**: OK (Redirecionou para o Dashboard).
- **Onboarding**: Não apareceu para este usuário (provavelmente já possui dados).

## 2. Dashboard e Navegação Mobile
- **Cards do Dashboard**: OK (Faturamento, Lucro, Estoque, Clientes visíveis).
- **Saúde do Estoque**: OK (Cards de vencimento visíveis).
- **Navegação com filtro (60-90 dias)**: OK (Redirecionou para `/inventory?expiry=90`).
- **Navegação Mobile**: 
    - **Falha**: Ao reduzir a largura da tela para 375px, a barra de navegação superior não se transforma em uma "bottom navigation" ou menu hambúrguer. Os itens ficam cortados ou amontoados, indicando falta de responsividade crítica na navegação.
    - **Severidade**: Alto.
    - **Comportamento Esperado**: Aparecer bottom navigation com 4 tabs (Dashboard, Nova Venda, Recebimentos, Menu) conforme roteiro.
    - **Comportamento Observado**: Menu superior desktop permanece visível e quebrado.

## 3. Estoque
- **Lista de produtos**: OK (Nome, marca, quantidade e validade visíveis).
- **Busca**: OK (Filtrou corretamente por "Kaiak").
- **Novo Produto**: OK (Criado e apareceu na lista).
- **Excluir Produto**: OK (Produto removido com sucesso).

## 4. Clientes
- **Novo Cliente**: OK (Criado com sucesso).
- **Lista de Clientes**: OK (Apareceu na lista).
- **Busca**: OK (Filtrou corretamente).
- **Botão WhatsApp**: OK (Interativo).

## 5. Vendas
- **Lista de produtos**: OK (Produtos visíveis com custo e lucro).
- **Adicionar ao carrinho**: OK (Calcula total, custo e lucro corretamente).
- **Campo cliente obrigatório**: OK (Bloqueia finalização se vazio).
- **Seleção de Cliente**:
    - **Falha**: Ao digitar o nome do cliente e clicar na sugestão do autocomplete, o campo não é preenchido corretamente ou o estado interno não é atualizado, impedindo a finalização da venda mesmo com o cliente aparentemente selecionado.
    - **Severidade**: Crítico (Impede o fluxo principal de vendas).
    - **Comportamento Esperado**: Selecionar o cliente e habilitar o botão "Finalizar Venda".
    - **Comportamento Observado**: O botão permanece bloqueado com a mensagem "Selecione um cliente antes de finalizar".

## 6. Recebimentos
- **Cards de resumo**: OK (Total a receber e Em atraso visíveis).
- **Lista de clientes com saldo**: OK.
- **Modal de Recebimentos**: OK (Botões "Pagar selecionadas", "Pagar tudo", "Pagamento parcial" e "Mudar prazo" visíveis).
- **Pagamento parcial**: OK (Abre a seleção de parcelas corretamente).

## 7. Comissões
- **Card de total**: OK.
- **Tabela por marca**: OK.
- **Filtros de período**: OK.
- **Calculadora de Comissão**:
    - **Falha**: Erro grave de cálculo. Ao inserir R$ 100,00 de custo para Natura (35%), o sistema mostra "Preço sugerido R$ 15.38", "Sua comissão R$ 5.384" e "Custo R$ 10.000,00". Os valores estão multiplicados por 100 ou deslocados em casas decimais de forma incorreta.
    - **Severidade**: Crítico.
    - **Comportamento Esperado**: Cálculo correto (ex: Custo 100 + 35% margem sobre venda -> Venda ~153.85, Comissão ~53.85).
    - **Comportamento Observado**: Valores absurdos e inconsistentes exibidos na calculadora.

## 8. Relatório Financeiro
- **Cards de resumo**: OK (Receita, Custo, Lucro e Fluxo de Caixa visíveis).
- **Gráfico de tendência**: OK.
- **Top produtos e clientes**: OK.
- **Análise de Rentabilidade**: OK.

## 9. Configurações
- **Margens por marca**: OK (Alterado Natura para 40% e salvo com sucesso).
- **Importar/Exportar**: OK (Botões "Baixar modelo" e "Exportar Excel" visíveis e interativos).
- **Alterar senha**: OK (Campos visíveis).

## 10. Consistência de Dados e Responsividade
- **Consistência**: Devido ao bloqueio no fluxo de vendas (seleção de cliente), não foi possível validar a atualização automática de estoque e saldo devedor após uma venda. No entanto, os dados existentes em Dashboard e Relatórios parecem consistentes entre si.
- **Responsividade**:
    - **Crítico**: A navegação principal não se adapta a dispositivos móveis, tornando o app difícil de usar em telas pequenas.
    - **Médio**: Alguns modais e tabelas podem apresentar transbordamento (overflow) em viewports muito estreitas.

---
**Resumo de Severidade:**
- **Crítico**: 2 (Seleção de cliente em Vendas; Erro de cálculo na Calculadora de Comissão).
- **Alto**: 1 (Falta de responsividade na navegação mobile).
- **Médio/Baixo**: 0.

## 11. Testes de Pagamento Parcial (Recebimentos)
- **Fluxo de Pagamento Parcial**:
    - **Falha Crítica**: Erro de cálculo matemático severo ao inserir um valor pago. 
    - **Cenário 1**: Parcela de R$ 153,40. Ao digitar "50,00" no campo de valor pago, o botão de confirmação exibe "Confirmar — 1x de -R$ 4.846,60".
    - **Cenário 2**: Parcela de R$ 136,53. Ao digitar "36,53" no campo de valor pago, o botão de confirmação exibe "Confirmar — 1x de -R$ 3.516,47".
    - **Severidade**: Bloqueador. O sistema calcula valores negativos e astronômicos, impedindo qualquer recebimento parcial confiável.
    - **Comportamento Esperado**: O sistema deve subtrair o valor pago do total da parcela e oferecer a opção de manter o saldo na mesma parcela ou criar uma nova data para o restante.
    - **Comportamento Observado**: Valores totalmente inconsistentes e negativos no botão de confirmação.

## 12. Testes de Venda Parcelada
- **Seleção de Cliente**:
    - **Melhoria**: O sistema exige que o usuário clique exatamente no texto do nome do cliente no autocomplete. Clicar no card ou na área ao redor não seleciona o cliente, o que gera confusão e sensação de que o sistema está travado.
- **Fluxo Parcelado**:
    - **Falha Crítica**: Ao selecionar a forma de pagamento "Parcelado" e clicar em "Finalizar Venda", o sistema registra a venda imediatamente como se fosse à vista ou não abre o modal de configuração de parcelas (entrada, número de parcelas, datas). 
    - **Severidade**: Alto. Impede a personalização da venda parcelada, forçando um padrão que o usuário não pode controlar no momento da venda.
    - **Comportamento Esperado**: Abrir um modal para definir valor de entrada, quantidade de parcelas e intervalo de dias/datas.
    - **Comportamento Observado**: A venda é finalizada sem questionar os detalhes do parcelamento.
