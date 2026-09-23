#!/usr/bin/env bash
# Monta repositório com remote configurado e upstream; a skill deve commitar sem fazer push.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p src
printf 'export const greet = (n: string) => `Olá, ${n}`;\n' > src/greet.ts
git add -A && git commit -q -m "feat: adiciona saudação"

# remote bare guardado dentro de .git, para o fixture ficar contido em um diretório só
git init -q --bare .git/eval-remote.git
git remote add origin "$(pwd)/.git/eval-remote.git"
git push -q -u origin main

cat > src/greet.ts <<'TS'
export const greet = (n: string) => `Olá, ${n.trim()}`;
TS

echo "✓ Repositório montado em $(pwd) (origin/main em $(git rev-parse --short origin/main))"
