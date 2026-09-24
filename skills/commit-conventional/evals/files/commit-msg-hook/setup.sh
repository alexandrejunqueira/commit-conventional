#!/usr/bin/env bash
# Monta monorepo com commitlint no hook commit-msg (estilo husky). O escopo é obrigatório e a lista
# de escopos é calculada a partir das pastas em packages/ (como @commitlint/config-pnpm-scopes),
# então não aparece escrita em nenhum config. O histórico não usa escopo.
# Uso: bash setup.sh <diretório-destino>
set -euo pipefail

DEST="${1:?informe o diretório de destino}"
[ -e "$DEST" ] && { echo "✗ $DEST já existe" >&2; exit 1; }
mkdir -p "$DEST" && cd "$DEST"

git init -q -b main
git config user.name "Eval Bot"
git config user.email "eval@example.com"
git config commit.gpgsign false

mkdir -p packages/cart/src packages/api/src
printf 'node_modules/\n' > .gitignore
printf 'export const items: string[] = [];\n' > packages/cart/src/items.ts
printf 'export const ping = () => "pong";\n' > packages/api/src/ping.ts
cat > commitlint.config.js <<'JS'
module.exports = { extends: ["@acme/commitlint-config"] };
JS
git add -A && git commit -q -m "feat: adiciona carrinho e rota de ping"
git switch -q -c feat/cart-clear

# config compartilhado do time, instalado como dependência (fora do git)
mkdir -p node_modules/@acme/commitlint-config node_modules/.bin
cat > node_modules/@acme/commitlint-config/index.js <<'JS'
const { readdirSync } = require("fs");
const { join } = require("path");

// escopos permitidos = pacotes do monorepo, lidos em tempo de execução
const workspaceScopes = () =>
  readdirSync(join(process.cwd(), "packages"), { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name);

module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-empty": [2, "never"],
    "scope-enum": () => [2, "always", workspaceScopes()],
  },
};
JS
# commitlint simplificado: resolve o extends, avalia regras que são funções e valida o header
cat > node_modules/.bin/commitlint <<'JS'
#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const cfg = require(path.join(process.cwd(), "commitlint.config.js"));
const shared = require(path.join(process.cwd(), "node_modules", cfg.extends[0]));
const rules = Object.fromEntries(
  Object.entries(shared.rules).map(([k, v]) => [k, typeof v === "function" ? v() : v])
);
const args = process.argv.slice(2);
if (args[0] === "--print-config") { console.log(JSON.stringify({ rules }, null, 2)); process.exit(0); }
const raw = args[0] === "--edit" ? fs.readFileSync(args[1], "utf8") : fs.readFileSync(0, "utf8");
const header = raw.split("\n")[0];
const m = header.match(/^(\w+)(?:\(([^)]*)\))?!?: /);
const problems = [];
if (!m) problems.push("header must be in format type(scope): subject [header-format]");
else {
  const scope = m[2];
  if (!scope && rules["scope-empty"][1] === "never") problems.push("scope may not be empty [scope-empty]");
  if (scope && !rules["scope-enum"][2].includes(scope))
    problems.push(`scope must be one of [${rules["scope-enum"][2].join(", ")}] [scope-enum]`);
}
if (problems.length) {
  console.error(`⧗   input: ${header}`);
  for (const p of problems) console.error(`✖   ${p}`);
  console.error(`✖   found ${problems.length} problems, 0 warnings`);
  process.exit(1);
}
JS
chmod +x node_modules/.bin/commitlint

cat > .git/hooks/commit-msg <<'SH'
#!/usr/bin/env sh
./node_modules/.bin/commitlint --edit "$1"
SH
chmod +x .git/hooks/commit-msg

cat > packages/cart/src/items.ts <<'TS'
export const items: string[] = [];
export const clear = () => items.splice(0, items.length);
TS

echo "✓ Repositório montado em $(pwd)"
