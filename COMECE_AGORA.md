# 🚀 COMECE AGORA - Primeiros Passos

## ✅ Passo 1: Criar Conta Appwrite (5 min)

1. Acesse: https://cloud.appwrite.io
2. Clique em "Sign Up"
3. Crie sua conta (email + senha ou GitHub)
4. Confirme seu email

## ✅ Passo 2: Criar Projeto (5 min)

1. No dashboard, clique em "Create Project"
2. Nome: `Bloquinho Digital`
3. Project ID: (será gerado automaticamente)
4. **ANOTE O PROJECT ID** - você vai precisar!

## ✅ Passo 3: Criar API Key (5 min)

1. No projeto, vá em "Settings" → "API Keys"
2. Clique em "Create API Key"
3. Nome: `Migration Script`
4. Scopes: Marque todos os de `databases.*`
5. Clique em "Create"
6. **COPIE A API KEY** (só aparece uma vez!)
7- standard_b851288d7710de774ab3e8625c5676dc427f120c36b8976585733b77cff6fc75c609e2f3e7a9bc721efa3b9538d4783e15faf82285bc7478959489b5f3f26b754d57276e90d29282701e6b19289094f295891d47a2b4ad8e82b3e14b9b436a20d8258c5fc6c4187e2e04861527d812e7af2b5837923297bece0af6f865856b9e

## ✅ Passo 4: Configurar Variáveis (5 min)

```bash
# Na raiz do projeto
cp .env.example .env
```

Edite o arquivo `.env` e preencha:

```env
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=seu-project-id-aqui
APPWRITE_API_KEY=sua-api-key-aqui
APPWRITE_DATABASE_ID=bloquinho
```

## ✅ Passo 5: Instalar Dependências (5 min)

```bash
cd tools
npm install
```

## ✅ Passo 6: Criar Collections (5 min)

```bash
npm run setup
```

Aguarde... O script vai criar:
- ✅ Database `bloquinho`
- ✅ 6 collections
- ✅ Todos os atributos
- ✅ Todos os índices

## 🎉 Pronto!

Você completou o setup inicial! Agora você pode:

### Opção A: Migrar Dados Agora
```bash
npm run migrate
```

### Opção B: Testar Primeiro
```bash
cd ../web
cp .env.example .env.local
# Edite .env.local com as configs do Appwrite
npm run dev
```

### Opção C: Ler Mais Documentação
- [INICIO_RAPIDO_APPWRITE.md](./INICIO_RAPIDO_APPWRITE.md)
- [CHECKLIST_MIGRACAO.md](./CHECKLIST_MIGRACAO.md)

## ⏱️ Tempo Total: 30 minutos

## 📞 Problemas?

Consulte: [FAQ_APPWRITE.md](./FAQ_APPWRITE.md)

---

**Você está indo muito bem! Continue! 💪**
