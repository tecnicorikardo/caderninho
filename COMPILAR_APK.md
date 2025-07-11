# 📱 Como Compilar o APK

## 🚀 Comandos Simples

### 1. Limpar e Preparar
```bash
flutter clean
flutter pub get
```

### 2. Compilar APK Release
```bash
flutter build apk --release --no-tree-shake-icons
```

### 3. Localizar o APK
O APK será gerado em:
```
build/app/outputs/flutter-apk/app-release.apk
```

## 🔧 Problemas Comuns

### ❌ Pasta build não aparece
**Solução**: A pasta `build/` é ignorada pelo `.gitignore` (normal). Ela só aparece após executar `flutter build`.

### ❌ Erro de compilação
**Soluções**:
1. Execute `flutter clean`
2. Execute `flutter pub get`
3. Verifique se todas as dependências estão corretas

### ❌ APK não é gerado
**Verifique**:
1. Se não há erros no console
2. Se o comando foi executado completamente
3. Se há espaço suficiente no disco

## 📋 Passos Completos

1. **Abra o terminal** na pasta do projeto
2. **Execute**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release --no-tree-shake-icons
   ```
3. **Aguarde** a compilação terminar
4. **Localize** o APK em `build/app/outputs/flutter-apk/app-release.apk`

## 🎯 Versões Disponíveis

### Trial (365 dias)
- Configure em `lib/config/app_config.dart`:
  ```dart
  static const bool isTrial = true;
  static const int trialDurationDays = 365;
  ```

### Vitalício
- Configure em `lib/config/app_config.dart`:
  ```dart
  static const bool isTrial = false;
  ```

## ✅ Correções Implementadas

- ✅ Modo escuro/claro adicionado na tela de configurações
- ✅ Debug detalhado para funcionalidade de contas
- ✅ Verificação de estrutura do banco
- ✅ Logs para identificar problemas

## 🧪 Como Testar

1. **Instale o APK** gerado
2. **Teste modo escuro/claro**: Configurações → Aparência
3. **Teste adicionar conta**: Minhas Contas → Botão de bug (🐛) → Verificar logs
4. **Verifique os logs** no console se houver problemas

---

**Última atualização**: Janeiro 2024
**Flutter**: 3.x 