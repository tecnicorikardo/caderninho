# bloquinhodigital (reset)

Este repositório foi limpo para recomeçar do zero, **mantendo o mesmo projeto Firebase** (`bloquinhodigital`) e as configurações essenciais:

- `.firebaserc`
- `firebase.json`
- `firestore.rules` / `firestore.indexes.json`
- `storage.rules`

## Hosting (placeholder)

O `firebase.json` aponta o Hosting para `public/`. Existe um `public/index.html` apenas para manter deploy/testes básicos funcionando.

## Reset de dados (Firestore/Auth)

Para **apagar todos os dados do Firestore** e **todos os usuários do Firebase Auth**, use o utilitário em `tools/firebase-wipe/`.

⚠️ Isso é irreversível. Use com cuidado e confirme o `projectId`.

