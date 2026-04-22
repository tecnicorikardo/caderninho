#!/bin/bash

echo "🧹 Limpando cache do Flutter..."
flutter clean

echo "📦 Baixando dependências..."
flutter pub get

echo "🚀 Iniciando app na web..."
flutter run -d chrome

echo "✅ Pronto! Teste o cancelamento de vendas."
