#!/usr/bin/env bash
# Monta repositório com hook commit-msg que exige escopo, embora o histórico não use escopo.
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
printf 'export const items: string[] = [];\n' > src/cart/items.ts
printf 'export const ping = () => "pong";\n' > src/api/ping.ts
git add -A && git commit -q -m "feat: adiciona carrinho e rota de ping"
git switch -q -c feat/cart-clear

# o time passou a exigir escopo agora; os commits antigos são anteriores ao hook
cat > .git/hooks/commit-msg <<'SH'
#!/usr/bin/env bash
header=$(head -1 "$1")
if ! printf '%s' "$header" | grep -qE '^[a-z]+\((cart|api)\)!?: '; then
  echo "✗ commitlint: scope-empty/scope-enum: o escopo é obrigatório e deve ser um de: cart, api" >&2
  echo "  recebido: $header" >&2
  exit 1
fi
SH
chmod +x .git/hooks/commit-msg

cat > src/cart/items.ts <<'TS'
export const items: string[] = [];
export const clear = () => items.splice(0, items.length);
TS

echo "✓ Repositório montado em $(pwd)"
