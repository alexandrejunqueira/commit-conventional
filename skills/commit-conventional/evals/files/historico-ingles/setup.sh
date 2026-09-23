#!/usr/bin/env bash
# Monta monorepo com histórico em inglês, escopos consolidados e commitlint com scope-enum.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p apps/web/src apps/api/src packages/shared
cat > commitlint.config.js <<'JS'
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: { "scope-enum": [2, "always", ["web", "api", "shared"]] },
};
JS
printf '# Monorepo\n' > README.md
git add -A && git commit -q -m "chore: set up monorepo with commitlint"

printf 'export const Header = () => <header>Store</header>;\n' > apps/web/src/Header.tsx
git add -A && git commit -q -m "feat(web): add store header"
printf 'export const health = () => ({ ok: true });\n' > apps/api/src/health.ts
git add -A && git commit -q -m "feat(api): add health check endpoint"
printf 'export const formatPrice = (c: number) => (c / 100).toFixed(2);\n' > packages/shared/price.ts
git add -A && git commit -q -m "feat(shared): add price formatter"
printf 'export const formatPrice = (c: number) => (c / 100).toFixed(2).replace(".", ",");\n' > packages/shared/price.ts
git add -A && git commit -q -m "fix(shared): use comma as decimal separator"

git switch -q -c feature/dark-mode
cat > apps/web/src/Header.tsx <<'TSX'
import { useState } from "react";

export const Header = () => {
  const [dark, setDark] = useState(false);
  return (
    <header className={dark ? "dark" : ""}>
      Store
      <button onClick={() => setDark(!dark)}>{dark ? "Light" : "Dark"} mode</button>
    </header>
  );
};
TSX

echo "✓ Repositório montado em $(pwd)"
