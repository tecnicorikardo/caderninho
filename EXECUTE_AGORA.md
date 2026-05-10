# 🚀 EXECUTE AGORA - Comandos Prontos

## ✅ Configuração Completa!

Tudo está configurado:
- ✅ Project ID: `caderninhodigitalapi`
- ✅ API Key: Configurada
- ✅ Arquivos .env: Prontos

## 📦 Passo 1: Instalar Dependências (2 min)

```bash
cd tools
npm install
```

Aguarde a instalação de:
- node-appwrite
- firebase-admin
- dotenv

## 🏗️ Passo 2: Criar Collections (5-10 min)

```bash
npm run setup
```

Ou diretamente:
```bash
node setup-appwrite-collections.js
```

### O que vai acontecer:

```
🚀 SETUP APPWRITE COLLECTIONS

📍 Endpoint: https://cloud.appwrite.io/v1
📍 Project: caderninhodigitalapi
📍 Database: bloquinho

🗄️  Criando database: bloquinho
   ✓ Database criado: bloquinho

📦 Criando collection: Users Profiles
   ✓ Collection criada: users_profiles
   → Criando atributo: userId
   → Criando atributo: createdAt
   → Criando atributo: updatedAt
   ...
   ✓ Atributos criados
   → Criando índice: userId
   ✓ Índices criados
   ✅ Collection Users Profiles configurada com sucesso!

📦 Criando collection: Customers
   ...

📦 Criando collection: Inventory Items
   ...

📦 Criando collection: Sales
   ...

📦 Criando collection: Receivables
   ...

📦 Criando collection: Inventory Movements
   ...

✅ SETUP CONCLUÍDO COM SUCESSO!

Próximos passos:
1. Configure as variáveis de ambiente no web/.env.local
2. Execute o script de migração: node tools/migrate-to-appwrite.js
3. Teste a aplicação: cd web && npm run dev
```

## 🔄 Passo 3: Migrar Dados (Opcional)

Se você tem dados no Firebase:

```bash
npm run migrate
```

Ou diretamente:
```bash
node migrate-to-appwrite.js
```

### O que vai acontecer:

```
🚀 MIGRAÇÃO FIREBASE → APPWRITE

🔥 EXPORTANDO DADOS DO FIREBASE

📦 Exportando customers...
   ✓ 150 documentos exportados

📦 Exportando inventory...
   ✓ 75 documentos exportados

📦 Exportando sales...
   ✓ 320 documentos exportados

📦 Exportando receivables...
   ✓ 45 documentos exportados

📦 Exportando users...
   ✓ 10 perfis exportados

💾 Dados salvos em: ./export/firebase-export-1234567890.json

☁️  IMPORTANDO PARA APPWRITE

📥 Importando para users_profiles...
   ✓ 10/10 documentos importados
   📊 Sucesso: 10 | Erros: 0

📥 Importando para customers...
   ✓ 150/150 documentos importados
   📊 Sucesso: 150 | Erros: 0

...

✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!
```

## 🧪 Passo 4: Testar Aplicação

```bash
cd ../web
npm install
npm run dev
```

Acesse: http://localhost:5173

## 📊 Passo 5: Verificar no Console

Abra o console do Appwrite:
```
https://cloud.appwrite.io/console/project-caderninhodigitalapi/databases/bloquinho
```

Verifique:
- [ ] Database `bloquinho` existe
- [ ] 6 collections criadas
- [ ] Dados importados (se migrou)

## 🎉 Pronto!

Após executar estes passos, você terá:
- ✅ Appwrite totalmente configurado
- ✅ Collections criadas e prontas
- ✅ Dados migrados (se aplicável)
- ✅ Aplicação funcionando com Appwrite

## 🆘 Se Algo Der Errado

### Erro: "Project not found"
```bash
# Verificar .env
cat .env | grep PROJECT_ID
```

### Erro: "Invalid API key"
```bash
# Verificar .env
cat .env | grep API_KEY
```

### Erro: "Collection already exists"
- Normal se executar o script múltiplas vezes
- O script continua mesmo com esse erro

### Outros erros
Consulte: [FAQ_APPWRITE.md](./FAQ_APPWRITE.md)

---

## 💡 Comandos Resumidos

```bash
# 1. Instalar
cd tools && npm install

# 2. Setup
npm run setup

# 3. Migrar (opcional)
npm run migrate

# 4. Testar
cd ../web && npm install && npm run dev
```

---

**COMECE AGORA! Execute o primeiro comando! 🚀**

```bash
cd tools
npm install
```
