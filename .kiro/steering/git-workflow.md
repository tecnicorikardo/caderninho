---
inclusion: always
---

# Git Workflow

Sempre que finalizar uma tarefa ou conjunto de mudanças, fazer commit e push automaticamente.

## Regras

- Após qualquer alteração de código, sempre executar `git add`, `git commit` e `git push`
- Usar mensagens de commit descritivas em português no formato: `feat:`, `fix:`, `chore:`
- Nunca deixar mudanças sem commitar
- Repositório: `tecnicorikardo/caderninho` (origin)
- Branch principal: `main`

## Comandos padrão

```bash
git add .
git commit -m "feat: descrição da mudança"
git push origin main
```
