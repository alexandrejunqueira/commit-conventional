#!/usr/bin/env bash
# Monta repositório com mudanças não atômicas: refactor em auth, endpoint novo em api e mudança de CI.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p src/auth src/api .github/workflows

cat > src/auth/oauth.ts <<'TS'
export async function handleCallback(code: string) {
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    body: JSON.stringify({ code, grant_type: "authorization_code" }),
  });
  const data = await res.json();
  if (!data.access_token) throw new Error("token ausente");
  return data.access_token as string;
}
TS

cat > src/api/users.ts <<'TS'
import { db } from "../db";

export async function listUsers() {
  return db.user.findMany();
}
TS

cat > .github/workflows/deploy.yml <<'YML'
name: deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build
YML

git add -A && git commit -q -m "feat: inicializa projeto com auth, api e deploy"
git switch -q -c mixed-changes

# 1. refactor: extrai troca de token para função própria
cat > src/auth/oauth.ts <<'TS'
async function exchangeCodeForToken(code: string): Promise<string> {
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    body: JSON.stringify({ code, grant_type: "authorization_code" }),
  });
  const data = await res.json();
  if (!data.access_token) throw new Error("token ausente");
  return data.access_token;
}

export async function handleCallback(code: string) {
  return exchangeCodeForToken(code);
}
TS

# 2. feat: novo endpoint de busca por id
cat >> src/api/users.ts <<'TS'

export async function getUserById(id: string) {
  return db.user.findUnique({ where: { id } });
}
TS

# 3. ci: adiciona etapa de testes no pipeline
cat > .github/workflows/deploy.yml <<'YML'
name: deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
      - run: npm run build
YML

echo "✓ Repositório montado em $(pwd)"
