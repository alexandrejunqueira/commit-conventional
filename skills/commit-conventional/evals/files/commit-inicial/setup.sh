#!/usr/bin/env bash
# Monta repositório sem nenhum commit, com os arquivos base de um projeto Node.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

cat > package.json <<'JSON'
{ "name": "app", "version": "0.1.0", "private": true, "scripts": { "dev": "tsx src/index.ts" } }
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2022", "module": "NodeNext", "strict": true } }
JSON
printf 'DATABASE_URL=\n' > .env.example
printf 'node_modules/\n.env\n' > .gitignore
printf '# App\n\nAPI em Node.js com TypeScript.\n' > README.md

echo "✓ Repositório montado em $(pwd)"
