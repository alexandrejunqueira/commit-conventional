#!/usr/bin/env bash
# Monta repositório com mudanças staged e unstaged misturadas.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p src/profile
cat > README.md <<'MD'
# App

Aplicação de exemplo.
MD
git add -A && git commit -q -m "feat: inicializa projeto"
git switch -q -c feat/user-profile

# staged: componente e hook
cat > src/profile/useProfile.ts <<'TS'
import { useEffect, useState } from "react";

export function useProfile(userId: string) {
  const [profile, setProfile] = useState<{ name: string } | null>(null);
  useEffect(() => {
    fetch(`/api/users/${userId}`).then((r) => r.json()).then(setProfile);
  }, [userId]);
  return profile;
}
TS
cat > src/profile/ProfilePage.tsx <<'TSX'
import { useProfile } from "./useProfile";

export function ProfilePage({ userId }: { userId: string }) {
  const profile = useProfile(userId);
  if (!profile) return <p>Carregando...</p>;
  return <h1>{profile.name}</h1>;
}
TSX
git add src/profile/useProfile.ts src/profile/ProfilePage.tsx

# unstaged: teste novo (untracked) e README modificado
cat > src/profile/ProfilePage.test.tsx <<'TSX'
import { render, screen } from "@testing-library/react";
import { ProfilePage } from "./ProfilePage";

it("mostra carregando antes do perfil chegar", () => {
  render(<ProfilePage userId="1" />);
  expect(screen.getByText("Carregando...")).toBeTruthy();
});
TSX
cat >> README.md <<'MD'

## Perfil

A página de perfil fica em `src/profile/ProfilePage.tsx`.
MD

echo "✓ Repositório montado em $(pwd)"
