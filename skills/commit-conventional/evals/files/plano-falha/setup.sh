#!/usr/bin/env bash
# Monta repositório com três mudanças independentes; a do meio é barrada pelo pre-commit (console.log).
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p src/api docs .github/workflows
printf 'export const listUsers = () => [];\n' > src/api/users.ts
printf '# API\n' > docs/api.md
printf 'name: ci\non: [push]\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - run: npm ci && npm run build\n' > .github/workflows/ci.yml
git add -A && git commit -q -m "feat: inicializa projeto com api, docs e ci"
git switch -q -c mixed-changes

cat > .git/hooks/pre-commit <<'SH'
#!/usr/bin/env bash
if git diff --cached -U0 | grep -q '^+.*console\.log'; then
  echo "✗ lint: console.log encontrado no código staged" >&2
  git diff --cached --name-only | xargs grep -n 'console\.log' >&2 || true
  exit 1
fi
SH
chmod +x .git/hooks/pre-commit

# 1. docs: documenta a listagem de usuários
printf '# API\n\n- `listUsers()` retorna todos os usuários\n' > docs/api.md
# 2. feat: busca por id, com console.log esquecido
cat > src/api/users.ts <<'TS'
export const listUsers = () => [];
export const getUserById = (id: string) => {
  console.log("buscando", id);
  return listUsers().find((u: { id: string }) => u.id === id);
};
TS
# 3. ci: roda testes antes do build
printf 'name: ci\non: [push]\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - run: npm ci\n      - run: npm test\n      - run: npm run build\n' > .github/workflows/ci.yml

echo "✓ Repositório montado em $(pwd)"
