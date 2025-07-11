# 🔧 Solução de Problemas - APK Caderninho

## Problemas Identificados

### 1. ❌ Modo Escuro/Claro Removido
**Problema**: Ao criar o APK vitalício, a opção de modo escuro e claro foi removida.

**✅ SOLUÇÃO IMPLEMENTADA**:
- Adicionada seção "Aparência" na tela de configurações
- Opções disponíveis:
  - **Automático**: Segue a configuração do sistema
  - **Claro**: Sempre usar tema claro
  - **Escuro**: Sempre usar tema escuro

**📍 Localização**: Configurações → Aparência → Modo de Tema

### 2. ❌ Adicionar Conta Não Funciona
**Problema**: Ao tentar adicionar conta, a funcionalidade não está funcionando, mas adicionar cartão funciona.

**🔍 POSSÍVEIS CAUSAS**:
1. **Problema no banco de dados**: Tabela `contas` não criada corretamente
2. **Erro no ContasService**: Problema na inserção de dados
3. **Problema de permissões**: App sem permissão para escrever no banco
4. **Erro no formulário**: Validação ou conversão de dados

**✅ SOLUÇÕES IMPLEMENTADAS**:

#### A. Debug Adicionado
- Logs detalhados no console para identificar o problema
- Verificação de cada etapa do processo de salvamento

#### B. Verificação da Estrutura do Banco
```sql
-- Tabela contas deve ter esta estrutura:
CREATE TABLE contas (
  id TEXT PRIMARY KEY,
  nome TEXT NOT NULL,
  valor REAL NOT NULL,
  vencimento INTEGER NOT NULL,
  status INTEGER NOT NULL,
  dataPagamento INTEGER,
  dataCriacao INTEGER NOT NULL,
  observacoes TEXT
)
```

#### C. Teste de Funcionalidade
Execute o script `teste_contas.bat` para verificar:
- Se o Flutter está funcionando
- Se as dependências estão corretas
- Se há erros de compilação
- Se o banco está sendo criado

## 🛠️ Como Testar

### 1. Teste do Modo Escuro/Claro
1. Abra o app
2. Vá para **Configurações**
3. Role até a seção **Aparência**
4. Teste as três opções:
   - Automático
   - Claro
   - Escuro
5. Verifique se o tema muda corretamente

### 2. Teste de Adicionar Conta
1. Abra o app
2. Vá para **Minhas Contas**
3. Clique no botão **+** (FloatingActionButton)
4. Selecione **Nova Conta**
5. Preencha os campos:
   - Nome da Conta: "Teste"
   - Valor: "100,00"
   - Vencimento: Escolha uma data
   - Observações: "Teste de funcionalidade"
6. Clique em **Adicionar**
7. Verifique se a conta aparece na lista

### 3. Verificação de Logs
Se houver problemas, verifique os logs no console:
```
🔍 Debug: Iniciando salvamento de conta...
🔍 Debug: Valor convertido: 100.0
🔍 Debug: Data vencimento: 2024-01-15
🔍 Debug: Conta criada: {id: ..., nome: ..., valor: 100.0, ...}
🔍 Debug: Inserindo nova conta...
🔍 Debug: Conta inserida com sucesso!
```

## 🚨 Problemas Comuns e Soluções

### Problema: "Erro ao salvar conta"
**Possíveis causas**:
1. **Banco de dados não criado**: Reinstale o app
2. **Permissões**: Verifique permissões de armazenamento
3. **Dados inválidos**: Verifique se os valores estão corretos

### Problema: "Tema não muda"
**Possíveis causas**:
1. **ConfigService não carregado**: Reinicie o app
2. **Cache do sistema**: Limpe o cache do app
3. **Versão do Flutter**: Atualize o Flutter

### Problema: "App não compila"
**Soluções**:
1. Execute `flutter clean`
2. Execute `flutter pub get`
3. Execute `flutter build apk --debug --no-tree-shake-icons`

## 📱 Comandos Úteis

### Limpar e Recompilar
```bash
flutter clean
flutter pub get
flutter build apk --debug --no-tree-shake-icons
```

### Verificar Dependências
```bash
flutter doctor
flutter pub deps
```

### Testar em Dispositivo
```bash
flutter run --debug
```

## 🔍 Verificações Adicionais

### 1. Verificar Banco de Dados
- O banco SQLite deve estar em `/data/data/com.example.app/databases/`
- Tabela `contas` deve existir com a estrutura correta

### 2. Verificar Permissões
- App deve ter permissão de armazenamento
- Em Android 11+, verificar permissões de arquivos

### 3. Verificar Logs
- Use `adb logcat` para ver logs detalhados
- Procure por erros relacionados ao SQLite

## 📞 Suporte

Se os problemas persistirem:
1. Execute o script `teste_contas.bat`
2. Verifique os logs no console
3. Teste em um dispositivo limpo
4. Verifique se há atualizações do Flutter

---

**Última atualização**: Janeiro 2024
**Versão do app**: 1.0.0
**Flutter**: 3.x 