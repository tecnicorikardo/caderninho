# 🚀 Próximos Passos - Configuração Completa

## ✅ Status Atual

- [x] Conta Appwrite criada
- [x] Projeto criado: `caderninhodigitalapi`
- [x] Arquivos .env configurados
- [ ] API Key criada
- [ ] Collections criadas
- [ ] Dados migrados

## 🔑 Passo 1: Criar API Key (AGORA)

### Acesse o Console
```
https://cloud.appwrite.io/console/project-caderninhodigitalapi/settings/keys
```

### Criar Key
1. Clique em "Create API Key"
2. Nome: `Migration Script`
3. Marque todos os scopes de `databases.*`
4. Clique em "Create"
5. **COPIE A KEY!**

### Adicionar ao .env
```bash
# Editar arquivo
notepad .env

# Substituir esta linha:
APPWRITE_API_KEY=sua-api-key-aqui

# Por:
APPWRITE_API_KEY=sua-key-copiada-aqui
```

## 🏗️ Passo 2: Instalar Dependências

```bash
cd tools
npm install
```

Isso vai instalar:
- `node-appwrite` - SDK do Appwrite
- `firebase-admin` - Para exportar dados do Firebase
- `dotenv` - Para ler variáveis de ambiente

## 🎯 Passo 3: Criar Collections

```bash
npm run setup
```

Ou diretamente:
```bash
node setup-appwrite-collections.js
```

O script vai:
1. ✅ Criar database `bloquinho`
2. ✅ Criar 6 collections:
   - users_profiles
   - customers
   - inventory_items
   - sales
   - receivables
   - inventory_movements
3. ✅ Criar todos os atributos
4. ✅ Criar todos os índices

**Tempo estimado:** 5-10 minutos

## 🔄 Passo 4: Migrar Dados (Opcional)

Se você já tem dados no Firebase:

```bash
npm run migrate
```

Ou diretamente:
```bash
node migrate-to-appwrite.js
```

O script vai:
1. ✅ Exportar dados do Firebase
2. ✅ Salvar backup em `tools/export/`
3. ✅ Importar para Appwrite
4. ✅ Mostrar estatísticas

**Tempo estimado:** 10-60 minutos (depende da quantidade de dados)

## 🧪 Passo 5: Testar Aplicação

```bash
cd ../web
npm install
npm run dev
```

Acesse: http://localhost:5173

Teste:
- [ ] Login/Cadastro
- [ ] Criar cliente
- [ ] Criar produto
- [ ] Criar venda
- [ ] Ver relatórios

## 📊 Passo 6: Verificar no Console

Acesse o console do Appwrite:
```
https://cloud.appwrite.io/console/project-caderninhodigitalapi
```

Verifique:
- [ ] Database `bloquinho` criado
- [ ] 6 collections criadas
- [ ] Dados importados (se migrou)

## 🎉 Pronto!

Após completar todos os passos, você terá:
- ✅ Appwrite configurado
- ✅ Collections criadas
- ✅ Dados migrados (se aplicável)
- ✅ Aplicação funcionando

## 🆘 Problemas?

### Erro: "Project not found"
- Verifique se o Project ID está correto no .env
- Confirme que está usando o endpoint correto

### Erro: "Invalid API key"
- Verifique se copiou a key completa
- Confirme que marcou os scopes corretos
- Tente criar uma nova key

### Erro ao criar collections
- Verifique se a API key tem permissões de `databases.*`
- Tente executar novamente (o script é idempotente)

### Outros problemas
Consulte: [FAQ_APPWRITE.md](./FAQ_APPWRITE.md)

## 📞 Precisa de Ajuda?

- [Discord Appwrite](https://appwrite.io/discord)
- [Documentação](https://appwrite.io/docs)
- [FAQ do Projeto](./FAQ_APPWRITE.md)

---

**Você está indo muito bem! Continue! 💪**

**Próximo:** Criar API Key e executar `npm run setup`
