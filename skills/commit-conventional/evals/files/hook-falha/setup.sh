#!/usr/bin/env bash
# Monta repositório com pre-commit hook que rejeita console.log, e uma mudança que tem console.log.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p src/cart
cat > src/cart/total.ts <<'TS'
export function total(items: { price: number; qty: number }[]) {
  return items.reduce((sum, i) => sum + i.price * i.qty, 0);
}
TS
git add -A && git commit -q -m "feat(cart): adiciona cálculo de total"
git switch -q -c feat/cart-discount

cat > .git/hooks/pre-commit <<'SH'
#!/usr/bin/env bash
if git diff --cached -U0 | grep -q '^+.*console\.log'; then
  echo "✗ lint: console.log encontrado no código staged" >&2
  git diff --cached --name-only | xargs grep -n 'console\.log' >&2 || true
  exit 1
fi
SH
chmod +x .git/hooks/pre-commit

cat > src/cart/total.ts <<'TS'
export function total(items: { price: number; qty: number }[], discount = 0) {
  const gross = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  console.log("gross", gross);
  return gross * (1 - discount);
}
TS

echo "✓ Repositório montado em $(pwd)"
