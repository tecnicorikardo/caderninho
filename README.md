# Caderninho do Comerciante

App Flutter para controle financeiro de pequenos comerciantes.

## Como Criar as Versões

### 1. Versão TRIAL (365 dias)
1. Editar: `lib/config/app_config.dart`
2. Manter: `static const int trialDurationDays = 365;`
3. Compilar: `flutter clean && flutter build apk --release --no-tree-shake-icons`
4. Renomear: `build/app/outputs/flutter-apk/app-release.apk` → `caderninho_trial_365_dias.apk`

### 2. Versão VITALÍCIA
1. Editar: `lib/config/app_config.dart`
2. Alterar: `static const int trialDurationDays = 9999999;`
3. Compilar: `flutter clean && flutter build apk --release --no-tree-shake-icons`
4. Renomear: `build/app/outputs/flutter-apk/app-release.apk` → `caderninho_vitalicio.apk`

## Estrutura do Projeto
- `lib/` - Código fonte
- `android/` - Configurações Android
- `assets/` - Recursos do app
- `GUIA_MANUAL.md` - Guia detalhado

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
