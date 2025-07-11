# GUIA MANUAL - CRIAR VERSÕES TRIAL E VITALÍCIA

## PASSO 1: CRIAR VERSÃO TRIAL (365 dias)

1. **Editar o arquivo:** `lib/config/app_config.dart`
2. **Configurar como:**
   ```dart
   static const bool isTrial = true;
   static const int trialDurationDays = 365;
   static const bool allowTrialReset = true;  // true = cliente pode resetar
   ```

## PASSO 2: COMPILAR VERSÃO TRIAL

```bash
flutter clean
flutter build apk --release --no-tree-shake-icons
```

4. **Renomear o APK gerado:**
   - Vá para: `build/app/outputs/flutter-apk/`
   - Copie `app-release.apk` para a raiz do projeto
   - Renomeie para: `caderninho_trial_365_dias.apk`

## PASSO 3: CRIAR VERSÃO VITALÍCIA

1. **Editar o arquivo:** `lib/config/app_config.dart`
2. **Configurar como:**
   ```dart
   static const bool isTrial = false;
   static const int trialDurationDays = 365;
   static const bool allowTrialReset = false;  // false = cliente NÃO pode resetar
   ```

## PASSO 4: COMPILAR VERSÃO VITALÍCIA

```bash
flutter clean
flutter build apk --release --no-tree-shake-icons
```

4. **Renomear o APK gerado:**
   - Vá para: `build/app/outputs/flutter-apk/`
   - Copie `app-release.apk` para a raiz do projeto
   - Renomeie para: `caderninho_vitalicio.apk`

## CONFIGURAÇÕES ADICIONAIS

### Para Trial SEM botão de reset:
```dart
static const bool isTrial = true;
static const int trialDurationDays = 365;
static const bool allowTrialReset = false;  // Cliente NÃO pode resetar
```

### Para Trial COM botão de reset:
```dart
static const bool isTrial = true;
static const int trialDurationDays = 365;
static const bool allowTrialReset = true;   // Cliente pode resetar
```

## RESULTADO FINAL

Você terá na raiz do projeto:
- `caderninho_trial_365_dias.apk` (versão trial)
- `caderninho_vitalicio.apk` (versão vitalícia)

## OBSERVAÇÕES

- Use sempre `--no-tree-shake-icons` para evitar problemas
- Sempre faça `flutter clean` antes de cada compilação
- Os APKs ficam em: `build/app/outputs/flutter-apk/app-release.apk`
- **IMPORTANTE:** Para versão vitalícia, mude `isTrial = false`
- **NOVO:** `allowTrialReset` controla se o cliente pode resetar o trial 