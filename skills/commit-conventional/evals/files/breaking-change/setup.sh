#!/usr/bin/env bash
# Monta repositório com renomeação de endpoint público (/users -> /accounts).
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p src/routes src/client docs
cat > src/routes/users.ts <<'TS'
import { Router } from "express";

export const usersRouter = Router();

usersRouter.get("/users", (_req, res) => res.json([]));
usersRouter.get("/users/:id", (req, res) => res.json({ id: req.params.id }));
TS
cat > src/server.ts <<'TS'
import express from "express";
import { usersRouter } from "./routes/users";

const app = express();
app.use(usersRouter);
app.listen(3000);
TS
cat > src/client/api.ts <<'TS'
export const listUsers = () => fetch("/users").then((r) => r.json());
export const getUser = (id: string) => fetch(`/users/${id}`).then((r) => r.json());
TS
cat > docs/api.md <<'MD'
# API

- `GET /users` lista usuários
- `GET /users/:id` retorna um usuário
MD
git add -A && git commit -q -m "feat: adiciona rotas de usuários"
git switch -q -c feat/rename-users-to-accounts

# renomeia rota e atualiza referências, sem stage
mv src/routes/users.ts src/routes/accounts.ts
cat > src/routes/accounts.ts <<'TS'
import { Router } from "express";

export const accountsRouter = Router();

accountsRouter.get("/accounts", (_req, res) => res.json([]));
accountsRouter.get("/accounts/:id", (req, res) => res.json({ id: req.params.id }));
TS
cat > src/server.ts <<'TS'
import express from "express";
import { accountsRouter } from "./routes/accounts";

const app = express();
app.use(accountsRouter);
app.listen(3000);
TS
cat > src/client/api.ts <<'TS'
export const listAccounts = () => fetch("/accounts").then((r) => r.json());
export const getAccount = (id: string) => fetch(`/accounts/${id}`).then((r) => r.json());
TS
cat > docs/api.md <<'MD'
# API

- `GET /accounts` lista contas
- `GET /accounts/:id` retorna uma conta
MD

echo "✓ Repositório montado em $(pwd)"
