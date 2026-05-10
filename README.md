# bloquinhodigital

PWA (React + TypeScript + Tailwind) para gestão comercial com suporte a Firebase e Appwrite.

## 🚀 Migração para Appwrite

**Novidade!** Documentação completa para migrar de Firebase para Appwrite disponível!

### 📚 Comece Aqui
- **[LEIA_PRIMEIRO_MIGRACAO.md](./LEIA_PRIMEIRO_MIGRACAO.md)** - Visão geral e próximos passos
- **[INICIO_RAPIDO_APPWRITE.md](./INICIO_RAPIDO_APPWRITE.md)** - Guia passo a passo
- **[INDICE_MIGRACAO_APPWRITE.md](./INDICE_MIGRACAO_APPWRITE.md)** - Índice completo

### 💡 Por Que Migrar?
- ✅ Economia de 80-95% nos custos
- ✅ Open source e sem vendor lock-in
- ✅ Possibilidade de self-hosted
- ✅ Controle total sobre os dados

### 📊 Documentação Disponível
1. Resumo Executivo (para decisores)
2. Comparação Firebase vs Appwrite
3. Guia completo de migração
4. Scripts automatizados
5. FAQ e troubleshooting
6. Checklist detalhado

## Estrutura

- `web/`: app PWA (Vite)
- `web/src/lib/adapters/`: Camada de abstração Firebase/Appwrite
- `functions/`: Cloud Functions (placeholder, MVP)
- `tools/`: Scripts de migração e setup
- `firestore.rules` / `firestore.indexes.json`: regras e índices do Firestore

## Rodar localmente

### Com Firebase (padrão)

1) Configure as variáveis do Firebase:

```bash
cd web
cp .env.example .env.local
# Edite .env.local com suas credenciais Firebase
```

2) Instale e rode:

```bash
npm install
npm run dev
```

### Com Appwrite (novo)

1) Configure as variáveis do Appwrite:

```bash
cd web
cp .env.example .env.local
# Edite .env.local com suas credenciais Appwrite
# Defina VITE_DB_PROVIDER=appwrite
```

2) Instale e rode:

```bash
npm install
npm run dev
```

## Deploy

### Firebase Hosting (atual)

```bash
cd web && npm run build
firebase deploy --only hosting
```

### Appwrite (futuro)

Após migração, o deploy pode ser feito em qualquer plataforma:
- Vercel
- Netlify
- Self-hosted
- Appwrite Cloud

## Migração

Para migrar de Firebase para Appwrite:

```bash
# 1. Ler documentação
cat LEIA_PRIMEIRO_MIGRACAO.md

# 2. Instalar dependências dos scripts
cd tools
npm install

# 3. Configurar variáveis de ambiente
cp ../.env.example ../.env
# Edite .env com suas credenciais

# 4. Criar collections no Appwrite
npm run setup

# 5. Migrar dados
npm run migrate

# 6. Testar aplicação
cd ../web
npm run dev
```

Veja [INICIO_RAPIDO_APPWRITE.md](./INICIO_RAPIDO_APPWRITE.md) para instruções detalhadas.
