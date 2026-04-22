# Guia de Deploy - Bloquinho Digital

## 📱 Deploy Web + APK Android

### Pré-requisitos
- Flutter instalado e configurado
- Firebase CLI instalado (`npm install -g firebase-tools`)
- Conta Firebase configurada
- Android SDK instalado (para APK)

---

## 🌐 Deploy Web (Firebase Hosting)

### Passo 1: Build do Flutter Web
```bash
cd mobile_flutter
flutter clean
flutter pub get
flutter build web --release
```

### Passo 2: Deploy no Firebase Hosting
```bash
cd ..
firebase deploy --only hosting
```

### Verificar Deploy
Após o deploy, acesse: https://bloquinhodigital.web.app

---

## 📦 Gerar APK Android

### Opção 1: APK Universal (Recomendado para testes)
```bash
cd mobile_flutter
flutter build apk --release
```

O APK será gerado em:
`mobile_flutter/build/app/outputs/flutter-apk/app-release.apk`

### Opção 2: APK Split por Arquitetura (Menor tamanho)
```bash
cd mobile_flutter
flutter build apk --split-per-abi --release
```

Serão gerados 3 APKs em `mobile_flutter/build/app/outputs/flutter-apk/`:
- `app-armeabi-v7a-release.apk` (ARM 32-bit - dispositivos antigos)
- `app-arm64-v8a-release.apk` (ARM 64-bit - maioria dos dispositivos modernos)
- `app-x86_64-release.apk` (Intel 64-bit - emuladores)

### Opção 3: App Bundle (Para Google Play Store)
```bash
cd mobile_flutter
flutter build appbundle --release
```

O bundle será gerado em:
`mobile_flutter/build/app/outputs/bundle/release/app-release.aab`

---

## 🔧 Configurações Importantes

### Versão do App
Edite `mobile_flutter/pubspec.yaml`:
```yaml
version: 1.0.0+1  # 1.0.0 = versionName, 1 = versionCode
```

Para atualizar:
```yaml
version: 1.0.1+2  # Incrementar ambos
```

### Ícone do App
O ícone está configurado em `img/icon.png`

Para regenerar os ícones:
```bash
cd mobile_flutter
flutter pub run flutter_launcher_icons
```

### Nome do App
Edite `mobile_flutter/android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="Bloquinho Digital"
    ...>
```

---

## 🚀 Deploy Completo (Web + Functions)

### Deploy Tudo
```bash
firebase deploy
```

### Deploy Apenas Hosting
```bash
firebase deploy --only hosting
```

### Deploy Apenas Functions
```bash
firebase deploy --only functions
```

### Deploy Apenas Firestore Rules
```bash
firebase deploy --only firestore:rules
```

---

## 📊 Verificar Status

### Ver logs do Firebase
```bash
firebase functions:log
```

### Ver configurações
```bash
firebase functions:config:get
```

### Testar localmente
```bash
firebase emulators:start
```

---

## 🔐 Assinatura do APK (Para Produção)

### 1. Criar Keystore (Primeira vez)
```bash
keytool -genkey -v -keystore ~/bloquinho-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias bloquinho
```

### 2. Configurar no Android
Crie `mobile_flutter/android/key.properties`:
```properties
storePassword=SUA_SENHA
keyPassword=SUA_SENHA
keyAlias=bloquinho
storeFile=/caminho/para/bloquinho-key.jks
```

### 3. Editar `mobile_flutter/android/app/build.gradle`
Adicione antes de `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Dentro de `android { buildTypes {`:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

---

## 📱 Instalar APK no Dispositivo

### Via USB (ADB)
```bash
adb install mobile_flutter/build/app/outputs/flutter-apk/app-release.apk
```

### Via Compartilhamento
1. Copie o APK para o celular
2. Abra o arquivo no celular
3. Permita instalação de fontes desconhecidas
4. Instale

---

## 🐛 Troubleshooting

### Erro: "Gradle build failed"
```bash
cd mobile_flutter/android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Erro: "Firebase not initialized"
Verifique se `google-services.json` está em:
`mobile_flutter/android/app/google-services.json`

### Erro: "Web build failed"
```bash
cd mobile_flutter
flutter clean
rm -rf build
flutter pub get
flutter build web --release
```

### APK muito grande
Use split por arquitetura:
```bash
flutter build apk --split-per-abi --release
```

---

## 📋 Checklist de Deploy

### Antes do Deploy Web:
- [ ] Testar localmente: `flutter run -d chrome`
- [ ] Verificar Firebase config
- [ ] Atualizar versão no pubspec.yaml
- [ ] Build: `flutter build web --release`
- [ ] Deploy: `firebase deploy --only hosting`

### Antes de Gerar APK:
- [ ] Testar no emulador Android
- [ ] Verificar google-services.json
- [ ] Atualizar versão no pubspec.yaml
- [ ] Atualizar ícone se necessário
- [ ] Build: `flutter build apk --release`
- [ ] Testar APK em dispositivo real

### Após Deploy:
- [ ] Testar app web em produção
- [ ] Testar APK em dispositivo real
- [ ] Verificar logs do Firebase
- [ ] Testar sistema de assinatura
- [ ] Testar webhooks do Mercado Pago

---

## 🎯 Comandos Rápidos

### Deploy Web Completo
```bash
cd mobile_flutter && flutter build web --release && cd .. && firebase deploy --only hosting
```

### Gerar APK
```bash
cd mobile_flutter && flutter build apk --release
```

### Deploy Tudo
```bash
cd mobile_flutter && flutter build web --release && cd .. && firebase deploy
```

---

## 📞 Suporte

- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074
