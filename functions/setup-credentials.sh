#!/bin/bash

# Script para configurar credenciais do Mercado Pago no Firebase Functions
# Uso: ./setup-credentials.sh

echo "🔧 Configuração de Credenciais - Bloquinho Digital"
echo "=================================================="
echo ""

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI não encontrado!"
    echo "📦 Instale com: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI encontrado"
echo ""

# Perguntar se quer usar credenciais de produção ou teste
echo "Qual ambiente você quer configurar?"
echo "1) Produção (credenciais reais)"
echo "2) Teste (credenciais de sandbox)"
read -p "Escolha (1 ou 2): " ambiente

if [ "$ambiente" == "1" ]; then
    echo ""
    echo "⚠️  ATENÇÃO: Você está configurando credenciais de PRODUÇÃO!"
    echo ""
    
    # Credenciais de produção fornecidas
    ACCESS_TOKEN="APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277"
    PUBLIC_KEY="APP_USR-abc96f3b-22e4-4032-aee6-b5f6e286b27c"
    CLIENT_SECRET="3u8B8HQwEPzOiOcUnZ3ciDNkXZxrfU3p"
    BASE_URL="https://bloquinhodigital.web.app"
    
    read -p "Usar credenciais fornecidas? (s/n): " usar_fornecidas
    
    if [ "$usar_fornecidas" != "s" ]; then
        read -p "Access Token: " ACCESS_TOKEN
        read -p "Public Key: " PUBLIC_KEY
        read -p "Client Secret: " CLIENT_SECRET
        read -p "Base URL [https://bloquinhodigital.web.app]: " BASE_URL
        BASE_URL=${BASE_URL:-https://bloquinhodigital.web.app}
    fi
    
elif [ "$ambiente" == "2" ]; then
    echo ""
    echo "🧪 Configurando ambiente de TESTE"
    echo ""
    
    read -p "Access Token (TEST): " ACCESS_TOKEN
    read -p "Public Key (TEST): " PUBLIC_KEY
    read -p "Client Secret (TEST): " CLIENT_SECRET
    read -p "Base URL [http://localhost:5000]: " BASE_URL
    BASE_URL=${BASE_URL:-http://localhost:5000}
else
    echo "❌ Opção inválida!"
    exit 1
fi

echo ""
echo "📝 Configurando no Firebase..."
echo ""

# Configurar no Firebase
firebase functions:config:set \
  mercadopago.access_token="$ACCESS_TOKEN" \
  mercadopago.public_key="$PUBLIC_KEY" \
  mercadopago.client_secret="$CLIENT_SECRET" \
  app.base_url="$BASE_URL"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Credenciais configuradas com sucesso!"
    echo ""
    echo "📋 Próximos passos:"
    echo "1. Verifique a configuração: firebase functions:config:get"
    echo "2. Faça deploy das functions: npm run deploy"
    echo ""
    
    read -p "Deseja ver a configuração atual? (s/n): " ver_config
    if [ "$ver_config" == "s" ]; then
        echo ""
        firebase functions:config:get
    fi
else
    echo ""
    echo "❌ Erro ao configurar credenciais!"
    echo "Verifique se você está logado no Firebase: firebase login"
    exit 1
fi

echo ""
echo "🎉 Configuração concluída!"
