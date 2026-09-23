#!/usr/bin/env bash

# commit-helper.sh - Coleta contexto automático para a skill commit-conventional
# Uso: ./commit-helper.sh [hint opcional]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HINT="${1:-}"

echo -e "${BLUE}=== Git Context Collector ===${NC}\n"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}✗ Erro: Não estamos em um repositório Git${NC}"
    exit 1
fi

BRANCH=$(git branch --show-current)
echo -e "${GREEN}✓ Branch atual:${NC} ${BLUE}$BRANCH${NC}"

ISSUE=$(echo "$BRANCH" | grep -oE '[0-9]+' | head -1)
if [ -n "$ISSUE" ]; then
    echo -e "  ${YELLOW}Issue detectada no branch: #${ISSUE}${NC}"
fi

echo -e "\n${GREEN}✓ Últimos 5 commits:${NC}"
git log --oneline -5 | sed 's/^/  /'

echo -e "\n${GREEN}✓ Staged:${NC}"
STAGED=$(git diff --name-only --cached)
if [ -z "$STAGED" ]; then
    echo -e "${YELLOW}  Nenhum arquivo staged${NC}"
else
    echo "$STAGED" | sed 's/^/  + /'
fi

echo -e "\n${GREEN}✓ Unstaged:${NC}"
UNSTAGED=$(git diff --name-only)
if [ -z "$UNSTAGED" ]; then
    echo -e "${YELLOW}  Nenhum arquivo unstaged${NC}"
else
    echo "$UNSTAGED" | sed 's/^/  ~ /'
fi

STATUS=$(git status --porcelain=v1)

echo -e "\n${GREEN}✓ Diff completo (HEAD):${NC}"
if ! git diff HEAD --quiet; then
    LINES=$(git diff HEAD | wc -l)
    echo "  Linhas no diff: $LINES"
else
    echo "  Sem changes staged ou unstaged"
fi

if [ -z "$STATUS" ]; then
    echo -e "\n${RED}✗ Nenhuma mudança detectada. Nada para fazer.${NC}"
    exit 1
fi

if [ -n "$HINT" ]; then
    echo -e "\n${GREEN}✓ Dica de contexto:${NC} ${BLUE}$HINT${NC}"
fi

echo -e "\n${BLUE}=== Pronto para gerar commit ===${NC}\n"
