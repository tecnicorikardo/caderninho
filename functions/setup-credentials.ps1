# Script para configurar credenciais do Mercado Pago no Firebase Functions
# Uso: .\setup-credentials.ps1

Write-Host "🔧 Configuração de Credenciais - Bloquinho Digital" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se Firebase CLI está instalado
$firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
    Write-Host "❌ Firebase CLI não encontrado!" -ForegroundColor Red
    Write-Host "📦 Instale com: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Firebase CLI encontrado" -ForegroundColor Green
Write-Host ""

# Perguntar se quer usar credenciais de produção ou teste
Write-Host "Qual ambiente você quer configurar?"
Write-Host "1) Produção (credenciais reais)"
Write-Host "2) Teste (credenciais de sandbox)"
$ambiente = Read-Host "Escolha (1 ou 2)"

if ($ambiente -eq "1") {
    Write-Host ""
    Write-Host "⚠️  ATENÇÃO: Você está configurando credenciais de PRODUÇÃO!" -ForegroundColor Yellow
    Write-Host ""
    
    # Credenciais de produção fornecidas
    $ACCESS_TOKEN = "APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277"
    $PUBLIC_KEY = "APP_USR-abc96f3b-22e4-4032-aee6-b5f6e286b27c"
    $CLIENT_SECRET = "3u8B8HQwEPzOiOcUnZ3ciDNkXZxrfU3p"
    $BASE_URL = "https://bloquinhodigital.web.app"
    
    $usar_fornecidas = Read-Host "Usar credenciais fornecidas? (s/n)"
    
    if ($usar_fornecidas -ne "s") {
        $ACCESS_TOKEN = Read-Host "Access Token"
        $PUBLIC_KEY = Read-Host "Public Key"
        $CLIENT_SECRET = Read-Host "Client Secret"
        $BASE_URL_INPUT = Read-Host "Base URL [https://bloquinhodigital.web.app]"
        if ($BASE_URL_INPUT) { $BASE_URL = $BASE_URL_INPUT }
    }
    
} elseif ($ambiente -eq "2") {
    Write-Host ""
    Write-Host "🧪 Configurando ambiente de TESTE" -ForegroundColor Cyan
    Write-Host ""
    
    $ACCESS_TOKEN = Read-Host "Access Token (TEST)"
    $PUBLIC_KEY = Read-Host "Public Key (TEST)"
    $CLIENT_SECRET = Read-Host "Client Secret (TEST)"
    $BASE_URL_INPUT = Read-Host "Base URL [http://localhost:5000]"
    $BASE_URL = if ($BASE_URL_INPUT) { $BASE_URL_INPUT } else { "http://localhost:5000" }
} else {
    Write-Host "❌ Opção inválida!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📝 Configurando no Firebase..." -ForegroundColor Cyan
Write-Host ""

# Configurar no Firebase
$configCmd = "firebase functions:config:set mercadopago.access_token=`"$ACCESS_TOKEN`" mercadopago.public_key=`"$PUBLIC_KEY`" mercadopago.client_secret=`"$CLIENT_SECRET`" app.base_url=`"$BASE_URL`""

try {
    Invoke-Expression $configCmd
    
    Write-Host ""
    Write-Host "✅ Credenciais configuradas com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
    Write-Host "1. Verifique a configuração: firebase functions:config:get"
    Write-Host "2. Faça deploy das functions: npm run deploy"
    Write-Host ""
    
    $ver_config = Read-Host "Deseja ver a configuração atual? (s/n)"
    if ($ver_config -eq "s") {
        Write-Host ""
        firebase functions:config:get
    }
    
    Write-Host ""
    Write-Host "🎉 Configuração concluída!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ Erro ao configurar credenciais!" -ForegroundColor Red
    Write-Host "Verifique se você está logado no Firebase: firebase login" -ForegroundColor Yellow
    exit 1
}
