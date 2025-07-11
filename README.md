# Caderninho do Comerciante

Sistema completo de gestão financeira para pequenos comerciantes desenvolvido em Flutter. Controle vendas, clientes, fiados, agenda e relatórios. Suporte a notificações automáticas, backup local e múltiplas formas de pagamento. Ideal para feirantes, prestadores de serviços e pequenos negócios.

## ✨ Principais Funcionalidades

### 🛒 Gestão de Vendas
- Registro de vendas com múltiplos produtos
- Diferentes formas de pagamento (dinheiro, cartão, PIX, fiado)
- Adicionais e descontos personalizados
- Histórico completo de transações

### 👥 Controle de Clientes
- Cadastro completo de clientes
- Histórico de compras por cliente
- Busca inteligente e filtros
- Compartilhamento de histórico via WhatsApp

### 💳 Sistema de Fiados
- Controle de vendas a prazo
- Registro de pagamentos parciais
- Notificações automáticas de vencimento
- Relatórios de fiados pendentes

### 📅 Agenda e Compromissos
- Calendário de compromissos
- Lembretes personalizáveis
- Notificações automáticas
- Resumo e estatísticas da agenda

### 🎰 Controle de Cassino (Específico)
- Gestão de casas de aposta
- Registro de depósitos e saques
- Relatórios financeiros
- Análise de lucros e perdas

### 📊 Relatórios e Análises
- Relatório de lucro por produto
- Análise de vendas por período
- Estatísticas de clientes
- Dashboard com resumos

### 🔔 Sistema de Notificações
- Notificações para fiados vencidos
- Lembretes de compromissos
- Alertas de contas a pagar
- Configuração de intervalos personalizados

### 💾 Backup e Segurança
- Backup local dos dados
- Exportação de relatórios
- Armazenamento seguro com SQLite
- Dados criptografados localmente

## 🛠️ Tecnologias Utilizadas
- **Flutter** - Framework de desenvolvimento
- **Dart** - Linguagem de programação
- **SQLite** - Banco de dados local
- **Shared Preferences** - Armazenamento de configurações
- **Permission Handler** - Gerenciamento de permissões
- **URL Launcher** - Integração com WhatsApp

## 📱 Compatibilidade
- ✅ **Android** - Versão principal
- ✅ **Windows** - Suporte desktop
- ⚠️ **iOS** - Configurado mas não testado

## 🚀 Como Criar as Versões

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

## 📁 Estrutura do Projeto
- `lib/` - Código fonte
- `android/` - Configurações Android
- `assets/` - Recursos do app
- `GUIA_MANUAL.md` - Guia detalhado

## 📚 Documentação
- `GUIA_MANUAL.md` - Guia completo de uso
- `COMPILAR_APK.md` - Instruções de compilação
- `IA_INTEGRACAO.md` - Documentação da IA

## 🤝 Contribuição
Este projeto é desenvolvido para atender às necessidades específicas de pequenos comerciantes. Contribuições são bem-vindas!

---

**Desenvolvido com ❤️ para facilitar a gestão financeira de pequenos negócios**
