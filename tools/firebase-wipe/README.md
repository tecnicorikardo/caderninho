# Firebase wipe (Firestore/Auth)

Este utilitário apaga:

- Todos os usuários do **Firebase Auth**
- Todos os documentos de todas as coleções do **Firestore** (recursivo)

⚠️ **Irreversível.**

## Pré-requisitos

- Node.js 18+ (recomendado 22)
- Uma credencial de Service Account com permissões de Admin

Sugestão: use `GOOGLE_APPLICATION_CREDENTIALS` apontando para o JSON da service account.

## Como usar

1) Instalar dependências:

`npm install`

2) Executar (exige confirmação do projectId):

`node wipe.js --projectId bloquinhodigital --confirm bloquinhodigital --deleteFirestore --deleteAuth`

Opcional (Storage):

`node wipe.js --projectId bloquinhodigital --confirm bloquinhodigital --deleteStorage`

