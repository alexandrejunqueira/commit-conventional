#!/usr/bin/env bash
# Monta repositório com um arquivo em stage parcial: a correção está staged, uma mudança não relacionada não.
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
  return items.reduce((sum, i) => sum + i.price, 0);
}

export function formatTotal(value: number) {
  return `R$ ${value}`;
}
TS
git add -A && git commit -q -m "feat(cart): adiciona cálculo de total"
git switch -q -c fix/cart-total-qty

# staged: corrige o total, que ignorava a quantidade
cat > src/cart/total.ts <<'TS'
export function total(items: { price: number; qty: number }[]) {
  return items.reduce((sum, i) => sum + i.price * i.qty, 0);
}

export function formatTotal(value: number) {
  return `R$ ${value}`;
}
TS
git add src/cart/total.ts

# unstaged, no mesmo arquivo: mudança de formatação não relacionada
cat > src/cart/total.ts <<'TS'
export function total(items: { price: number; qty: number }[]) {
  return items.reduce((sum, i) => sum + i.price * i.qty, 0);
}

export function formatTotal(value: number) {
  return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}
TS

echo "✓ Repositório montado em $(pwd)"
