# 🎨 COMO TROCAR O ÍCONE DO APP

## 📋 Instruções:

1. **Prepare sua imagem:**
   - Formato: PNG (recomendado) ou JPG
   - Tamanho: 1024x1024 pixels
   - Fundo transparente (se desejar)

2. **Nomeie o arquivo:**
   - Salve como: `icon.png`
   - Coloque nesta pasta: `assets/icon/icon.png`

3. **Execute o comando:**
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

4. **Rebuild o APK:**
   ```bash
   flutter build apk --release
   ```

## 🎯 Dicas:

- Use imagens de alta qualidade
- Evite texto muito pequeno no ícone
- Teste em dispositivos diferentes
- O ícone deve ser reconhecível em tamanhos pequenos

## 🖼️ Exemplos de bons ícones:
- Símbolos simples e claros
- Cores contrastantes
- Design minimalista
- Sem bordas desnecessárias

**Depois de adicionar o ícone, delete este arquivo README.md** 