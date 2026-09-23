#!/usr/bin/env bash
# Monta repositório com commitlint via hook commit-msg (estilo husky). A regra de escopo vem de um
# config compartilhado em node_modules, então não aparece lendo só o hook; o histórico não usa escopo.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p src/cart src/api
printf 'node_modules/\n' > .gitignore
printf 'export const items: string[] = [];\n' > src/cart/items.ts
printf 'export const ping = () => "pong";\n' > src/api/ping.ts
cat > commitlint.config.js <<'JS'
module.exports = { extends: ["@acme/commitlint-config"] };
JS
git add -A && git commit -q -m "feat: adiciona carrinho e rota de ping"
git switch -q -c feat/cart-clear

# config compartilhado do time, instalado como dependência (fora do git)
mkdir -p node_modules/@acme/commitlint-config node_modules/.bin
cat > node_modules/@acme/commitlint-config/index.js <<'JS'
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-empty": [2, "never"],
    "scope-enum": [2, "always", ["cart", "api"]],
  },
};
JS
# commitlint simplificado: aceita --edit <arquivo> (hook) ou a mensagem pela entrada padrão
cat > node_modules/.bin/commitlint <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = "--print-config" ]; then cat "$(dirname "$0")/../@acme/commitlint-config/index.js"; exit 0; fi
if [ "${1:-}" = "--edit" ]; then header=$(head -1 "$2"); else header=$(head -1); fi
if ! printf '%s' "$header" | grep -qE '^[a-z]+\([a-z]+\)!?: '; then
  echo "⧗   input: $header" >&2
  echo "✖   scope may not be empty [scope-empty]" >&2
  echo "✖   found 1 problems, 0 warnings" >&2
  exit 1
fi
if ! printf '%s' "$header" | grep -qE '^[a-z]+\((cart|api)\)!?: '; then
  echo "⧗   input: $header" >&2
  echo "✖   scope must be one of [cart, api] [scope-enum]" >&2
  echo "✖   found 1 problems, 0 warnings" >&2
  exit 1
fi
SH
chmod +x node_modules/.bin/commitlint

cat > .git/hooks/commit-msg <<'SH'
#!/usr/bin/env sh
./node_modules/.bin/commitlint --edit "$1"
SH
chmod +x .git/hooks/commit-msg

cat > src/cart/items.ts <<'TS'
export const items: string[] = [];
export const clear = () => items.splice(0, items.length);
TS

echo "✓ Repositório montado em $(pwd)"
