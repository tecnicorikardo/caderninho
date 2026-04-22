@echo off
echo Limpando cache do Flutter...
flutter clean

echo Baixando dependencias...
flutter pub get

echo Iniciando app na web...
flutter run -d chrome

echo Pronto! Teste o cancelamento de vendas.
pause
