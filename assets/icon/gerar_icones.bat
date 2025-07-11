@echo off
echo 🎨 Gerando ícones do aplicativo...
echo.
echo 📋 Certifique-se de que o arquivo icon.png está nesta pasta!
echo.
pause

echo 🔄 Executando flutter_launcher_icons...
flutter pub run flutter_launcher_icons:main

echo.
echo ✅ Ícones gerados com sucesso!
echo.
echo 📱 Para ver as mudanças:
echo 1. Execute: flutter build apk --release
echo 2. Instale o novo APK
echo.
pause 