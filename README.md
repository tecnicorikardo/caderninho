# bloquinhodigital

PWA (React + TypeScript + Tailwind) hospedado no Firebase Hosting, com Firebase Auth (e-mail/senha) e Firestore.

## Estrutura

- `web/`: app PWA (Vite)
- `functions/`: Cloud Functions (placeholder, MVP)
- `firestore.rules` / `firestore.indexes.json`: regras e índices do Firestore
- `tools/firebase-wipe/`: utilitário opcional para apagar Auth/Firestore (irreversível)

## Rodar localmente

1) Configure as variáveis do Firebase:

- `web/.env.local` (copie de `web/.env.example`)

2) Instale e rode:

- `cd web`
- `npm install`
- `npm run dev`

## Deploy (manual)

- `cd web && npm run build`
- `firebase deploy --only hosting`
