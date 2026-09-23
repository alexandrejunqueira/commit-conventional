#!/usr/bin/env bash
# Monta repositório com histórico em inglês fora do Conventional Commits e sem commitlint.
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
printf '# Notes app\n' > README.md
git add -A && git commit -q -m "Initial commit"
printf 'export const notes: string[] = [];\n' > src/notes.ts
git add -A && git commit -q -m "Add notes store"
printf 'export const notes: string[] = [];\nexport const add = (n: string) => notes.push(n);\n' > src/notes.ts
git add -A && git commit -q -m "Add function to create notes"
printf '# Notes app\n\nSimple notes app.\n' > README.md
git add -A && git commit -q -m "Update README"
git switch -q -c remove-notes

cat > src/notes.ts <<'TS'
export const notes: string[] = [];
export const add = (n: string) => notes.push(n);
export const remove = (i: number) => notes.splice(i, 1);
TS

echo "✓ Repositório montado em $(pwd)"
