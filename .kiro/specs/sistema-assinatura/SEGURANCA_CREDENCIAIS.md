# 🔒 SEGURANÇA: Como Proteger suas Credenciais

## ⚠️ REGRAS DE OURO

### ❌ NUNCA FAÇA ISSO:

1. ❌ Compartilhar credenciais em chats, emails ou mensagens
2. ❌ Commitar credenciais no Git/GitHub
3. ❌ Colocar credenciais diretamente no código
4. ❌ Compartilhar credenciais de PRODUÇÃO (só use TESTE para desenvolvimento)
5. ❌ Tirar print/screenshot de credenciais e compartilhar

### ✅ SEMPRE FAÇA ISSO:

1. ✅ Use credenciais de TESTE durante desenvolvimento
2. ✅ Guarde credenciais em variáveis de ambiente
3. ✅ Use Firebase Functions Config para produção
4. ✅ Adicione `.env` no `.gitignore`
5. ✅ Renove credenciais se foram expostas

## 🚨 SE VOCÊ EXPÔS SUAS CREDENCIAIS

### Passo 1: Renovar Imediatamente

1. Acesse: https://www.mercadopago.com.br/developers/panel
2. Vá em **"Credenciais"**
3. Clique em **"Renovar credenciais"** ou **"Gerar novas"**
4. Confirme a renovação
5. As credenciais antigas ficam inválidas imediatamente

### Passo 2: Verificar Transações

1. Acesse o painel do Mercado Pago
2. Verifique se há transações suspeitas
3. Se houver, entre em contato com o suporte do Mercado Pago

### Passo 3: Atualizar Sistema

1. Pegue as novas credenciais
2. Atualize no Firebase Functions Config
3. Faça deploy novamente

## 📝 Como Configurar Corretamente

### Durante Desenvolvimento (Local)

Crie um arquivo `.env` na pasta `functions/`:

```env
MERCADOPAGO_ACCESS_TOKEN=TEST-xxxxxxxxxxxx
MERCADOPAGO_PUBLIC_KEY=TEST-xxxxxxxxxxxx
```

Adicione ao `.gitignore`:
```
functions/.env
.env
*.env
```

### Em Produção (Firebase)

Use Firebase Functions Config:

```bash
# Configurar credenciais
firebase functions:config:set \
  mercadopago.access_token="SUA_CREDENCIAL_AQUI" \
  mercadopago.public_key="SUA_CREDENCIAL_AQUI"

# Ver configurações (não mostra valores completos)
firebase functions:config:get

# Remover configuração
firebase functions:config:unset mercadopago.access_token
```

### No Código

```javascript
// ✅ CORRETO - Usar variáveis de ambiente
const accessToken = functions.config().mercadopago.access_token;

// ❌ ERRADO - Nunca faça isso!
const accessToken = "APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277";
```

## 🔐 Boas Práticas

### 1. Use Credenciais de Teste Primeiro

Sempre desenvolva e teste com credenciais de TESTE:
- Começam com `TEST-`
- Não processam pagamentos reais
- Podem ser compartilhadas com desenvolvedores

### 2. Separe Ambientes

- **Desenvolvimento**: Credenciais de TESTE
- **Staging/Homologação**: Credenciais de TESTE
- **Produção**: Credenciais de PRODUÇÃO

### 3. Rotacione Credenciais Regularmente

- Renove credenciais a cada 6 meses
- Renove imediatamente se suspeitar de exposição
- Mantenha histórico de quando foram renovadas

### 4. Limite Acesso

- Só compartilhe credenciais com quem realmente precisa
- Use credenciais de TESTE para desenvolvedores
- Mantenha credenciais de PRODUÇÃO apenas com você

### 5. Monitore Transações

- Configure alertas no Mercado Pago
- Revise transações regularmente
- Investigue qualquer atividade suspeita

## 📞 Em Caso de Dúvidas

**Suporte Mercado Pago:**
- Site: https://www.mercadopago.com.br/ajuda
- Telefone: 0800 275 0405

**Desenvolvedor do Sistema:**
- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074

---

## ⚠️ LEMBRE-SE

**Credenciais são como senhas de banco!**

Trate-as com o mesmo cuidado que você trata:
- Senha do banco
- Senha do email
- Chaves de casa

**Se alguém pedir suas credenciais, desconfie!**
