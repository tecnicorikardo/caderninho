# ⚡ Comandos Rápidos - Migração Appwrite

## 🚀 Setup Inicial

### 1. Instalar Dependências

```bash
# Dependências dos scripts de migração
cd tools
npm install

# Dependências da aplicação web
cd ../web
npm install
```

### 2. Configurar Variáveis de Ambiente

```bash
# Copiar exemplos
cp .env.example .env
cp web/.env.example web/.env.local

# Editar com suas credenciais
# Linux/Mac:
nano .env
nano web/.env.local

# Windows:
notepad .env
notepad web\.env.local
```

## 🏗️ Criar Collections no Appwrite

```bash
# Executar script de setup
cd tools
npm run setup

# Ou diretamente:
node setup-appwrite-collections.js
```

## 🔄 Migrar Dados

```bash
# Executar migração completa
cd tools
npm run migrate

# Ou diretamente:
node migrate-to-appwrite.js
```

## 🧪 Testar Aplicação

### Com Firebase

```bash
cd web

# Configurar provider
echo "VITE_DB_PROVIDER=firebase" >> .env.local

# Rodar
npm run dev
```

### Com Appwrite

```bash
cd web

# Configurar provider
echo "VITE_DB_PROVIDER=appwrite" >> .env.local

# Rodar
npm run dev
```

## 🚀 Deploy

### Build

```bash
cd web
npm run build
```

### Deploy Firebase Hosting

```bash
firebase deploy --only hosting
```

### Deploy Vercel

```bash
cd web
vercel deploy
```

### Deploy Netlify

```bash
cd web
netlify deploy --prod
```

## 🔍 Verificação

### Verificar Instalação

```bash
# Node.js
node --version

# npm
npm --version

# Firebase CLI
firebase --version
```

### Verificar Configuração

```bash
# Ver variáveis de ambiente (sem valores)
cat .env | grep -v "="

# Verificar se collections foram criadas
# (Acesse console do Appwrite)
```

## 📊 Monitoramento

### Logs da Aplicação

```bash
# Desenvolvimento
cd web
npm run dev

# Ver logs em tempo real
# Abra o console do navegador (F12)
```

### Logs do Appwrite

```bash
# Self-hosted
docker logs appwrite -f

# Cloud
# Acesse console.appwrite.io → Logs
```

## 🆘 Troubleshooting

### Limpar Cache

```bash
# Limpar node_modules
rm -rf web/node_modules tools/node_modules
npm install

# Limpar build
rm -rf web/dist web/.next
```

### Resetar Configuração

```bash
# Remover variáveis de ambiente
rm .env web/.env.local

# Recriar do exemplo
cp .env.example .env
cp web/.env.example web/.env.local
```

### Verificar Erros

```bash
# TypeScript
cd web
npm run typecheck

# Lint
npm run lint

# Build
npm run build
```

## 🔧 Utilitários

### Backup do Firebase

```bash
# Exportar dados
cd tools
node migrate-to-appwrite.js

# Dados salvos em: tools/export/
```

### Verificar Dados no Appwrite

```bash
# Via console
# https://cloud.appwrite.io

# Via API (exemplo)
curl -X GET \
  'https://cloud.appwrite.io/v1/databases/bloquinho/collections/customers/documents' \
  -H 'X-Appwrite-Project: YOUR_PROJECT_ID' \
  -H 'X-Appwrite-Key: YOUR_API_KEY'
```

## 📦 Scripts Personalizados

### Adicionar ao package.json

```json
{
  "scripts": {
    "migrate:setup": "cd tools && npm run setup",
    "migrate:data": "cd tools && npm run migrate",
    "migrate:full": "npm run migrate:setup && npm run migrate:data",
    "dev:firebase": "cd web && VITE_DB_PROVIDER=firebase npm run dev",
    "dev:appwrite": "cd web && VITE_DB_PROVIDER=appwrite npm run dev"
  }
}
```

### Usar scripts

```bash
# Setup completo
npm run migrate:setup

# Migração de dados
npm run migrate:data

# Migração completa
npm run migrate:full

# Dev com Firebase
npm run dev:firebase

# Dev com Appwrite
npm run dev:appwrite
```

## 🐳 Docker (Self-Hosted)

### Instalar Appwrite

```bash
# Baixar e executar
docker run -d \
  --name appwrite \
  -p 80:80 -p 443:443 \
  -v appwrite-data:/storage \
  appwrite/appwrite:latest
```

### Gerenciar Container

```bash
# Ver status
docker ps | grep appwrite

# Ver logs
docker logs appwrite -f

# Parar
docker stop appwrite

# Iniciar
docker start appwrite

# Remover
docker rm -f appwrite
```

## 🔐 Segurança

### Gerar API Key

```bash
# Via console Appwrite
# Settings → API Keys → Create API Key

# Salvar em .env
echo "APPWRITE_API_KEY=sua-key-aqui" >> .env
```

### Rotacionar Keys

```bash
# 1. Criar nova key no console
# 2. Atualizar .env
# 3. Testar aplicação
# 4. Deletar key antiga
```

## 📊 Estatísticas

### Contar Documentos

```bash
# Firebase (via console)
# https://console.firebase.google.com

# Appwrite (via console)
# https://cloud.appwrite.io
```

### Verificar Uso

```bash
# Appwrite Cloud
# Console → Usage

# Self-hosted
docker stats appwrite
```

## 🎯 Atalhos Úteis

### Desenvolvimento

```bash
# Abrir projeto no VS Code
code .

# Abrir console Appwrite
open https://cloud.appwrite.io

# Abrir console Firebase
open https://console.firebase.google.com
```

### Git

```bash
# Commit da migração
git add .
git commit -m "feat: migração para Appwrite"
git push

# Criar branch de migração
git checkout -b feature/appwrite-migration
```

## 📚 Documentação Rápida

### Abrir Documentos

```bash
# Linux/Mac
open LEIA_PRIMEIRO_MIGRACAO.md
open INICIO_RAPIDO_APPWRITE.md

# Windows
start LEIA_PRIMEIRO_MIGRACAO.md
start INICIO_RAPIDO_APPWRITE.md
```

### Buscar na Documentação

```bash
# Buscar termo
grep -r "termo" *.md

# Buscar em arquivo específico
grep "termo" INICIO_RAPIDO_APPWRITE.md
```

## 🔄 Rollback Rápido

### Voltar para Firebase

```bash
# 1. Mudar provider
cd web
sed -i 's/VITE_DB_PROVIDER=appwrite/VITE_DB_PROVIDER=firebase/' .env.local

# 2. Rebuild
npm run build

# 3. Deploy
firebase deploy --only hosting
```

## 🎉 Comandos de Sucesso

### Após Migração Bem-Sucedida

```bash
# Celebrar! 🎉
echo "🎉 Migração concluída com sucesso!"

# Verificar economia
echo "💰 Economia estimada: $725 em 3 anos"

# Próximos passos
cat << EOF
✅ Migração completa!
✅ Dados migrados
✅ Aplicação testada
✅ Deploy realizado

📊 Próximos passos:
1. Monitorar por 30 dias
2. Coletar feedback
3. Otimizar performance
4. Desativar Firebase
EOF
```

## 📞 Ajuda Rápida

```bash
# Ver comandos disponíveis
npm run

# Ver versões
node --version
npm --version

# Ver ajuda dos scripts
cd tools
node setup-appwrite-collections.js --help
node migrate-to-appwrite.js --help
```

## 🔗 Links Úteis

```bash
# Abrir links importantes
open https://appwrite.io/docs
open https://cloud.appwrite.io
open https://appwrite.io/discord
open https://github.com/appwrite/appwrite
```

---

## 💡 Dicas

### Aliases Úteis (Bash/Zsh)

Adicione ao seu `~/.bashrc` ou `~/.zshrc`:

```bash
# Aliases para migração Appwrite
alias migrate-setup='cd tools && npm run setup'
alias migrate-data='cd tools && npm run migrate'
alias dev-firebase='cd web && VITE_DB_PROVIDER=firebase npm run dev'
alias dev-appwrite='cd web && VITE_DB_PROVIDER=appwrite npm run dev'
```

### Recarregar aliases

```bash
source ~/.bashrc
# ou
source ~/.zshrc
```

### Usar aliases

```bash
migrate-setup
migrate-data
dev-firebase
dev-appwrite
```

---

**Precisa de mais ajuda? Consulte [FAQ_APPWRITE.md](./FAQ_APPWRITE.md)! 🚀**
