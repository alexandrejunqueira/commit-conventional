#!/usr/bin/env bash
# Monta repositório em branch com número dentro de palavra (oauth2), que não é issue.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p src/auth
printf '# App\n' > README.md
git add -A && git commit -q -m "feat: inicializa projeto"
git switch -q -c feat/oauth2-google

cat > src/auth/google.ts <<'TS'
const AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";

export function googleLoginUrl(clientId: string, redirectUri: string) {
  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: "openid email profile",
  });
  return `${AUTH_URL}?${params}`;
}
TS

echo "✓ Repositório montado em $(pwd)"
