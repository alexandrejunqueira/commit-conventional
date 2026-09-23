---
name: commit-conventional
description: Gera commits com mensagens Conventional Commits de alta qualidade em português. Ative sempre que o usuário quiser fazer commit de mudanças no Git, seja com um simples "commit", "commita isso" ou "fazer commit das mudanças". Analisa o diff, gera 3 candidatos de mensagem seguindo a spec Conventional Commits, seleciona o melhor, faz stage dos arquivos relevantes e executa o commit. Detecta diffs não atômicos e recomenda dividir antes de commitar. Ideal para manter histórico limpo e rastreável em monorepos, pipelines de CI/CD e projetos com ADRs.
license: MIT
compatibility: Git instalado; repositório Git válido com mudanças staged ou unstaged
metadata:
  author: Alexandre Junqueira
  version: "1.0.0"
---

# Skill: commit-conventional

Automatiza a criação de commits de alta qualidade seguindo a especificação Conventional Commits, com suporte bilíngue e heurísticas para atomicidade.

## Contexto Automático

Antes de gerar mensagens, coleta:
- Branch atual
- Últimos 5 commits
- Status do repositório (staged + unstaged)
- Diff completo (HEAD)

## Fluxo de Trabalho

### 1. Análise de Mudanças
Leia o diff completo para entender:
- **Natureza**: que tipo de mudança foi feita (nova feature, bug, refactor, etc)
- **Propósito**: por quê a mudança foi feita
- **Escopo**: qual área/módulo foi afetada
- **Atomicidade**: se o diff toca múltiplas áreas **não relacionadas**, **recomende dividir em commits atômicos** antes de prosseguir

### 2. Geração de Candidatos
Gere **3 candidatos** de mensagem de commit usando este template exato:

```
**Candidato 1 (literal):** `tipo(escopo): descrição`
**Candidato 2 (impacto):** `tipo(escopo): descrição`
**Candidato 3 (intenção):** `tipo(escopo): descrição`

**Escolha:** Candidato N — [justificativa em 1 linha]
```

Cada candidato deve seguir a spec abaixo.

### 3. Seleção e Justificativa
Escolha o melhor candidato com **1-2 linhas de raciocínio**. Critérios:
- Clareza da descrição imperativa
- Relevância do escopo
- Aderência à spec (tamanho, tipo correto)
- Precisão quanto ao propósito das mudanças

### 4. Staging
- Se houver apenas unstaged changes, faça `git add` dos arquivos relevantes
- Se houver staged changes, respeite e não altere
- Se mixed (staged + unstaged), pergunte ao usuário qual estratégia usar

### 5. Commit
Execute o commit com a mensagem escolhida usando `git commit -m`.

## Especificação de Mensagem

### Formato Padrão

```
<tipo>(<escopo opcional>): <descrição imperativa em PT-BR>

[corpo opcional — o quê e por quê, não o como]

[footer opcional — refs, breaking changes]
```

### Tipos Válidos

| Tipo | Uso |
|------|-----|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `docs` | Apenas documentação |
| `style` | Formatação, sem lógica |
| `refactor` | Refatoração sem feature/fix |
| `perf` | Melhoria de performance |
| `test` | Adicionar/corrigir testes |
| `chore` | Build, deps, configuração |
| `ci` | Mudanças de CI/CD |

### Regras de Escopo

- Use escopo se **>70% dos arquivos modificados pertencem ao mesmo módulo/diretório** identificável
  - Ex: 8 de 10 arquivos em `src/auth/` → `feat(auth):`
- **Omita** se mudanças estão distribuídas por múltiplos módulos sem um dominante claro
- Exemplos válidos: `feat(auth):`, `fix(api):`, `docs(setup):`

### Heurísticas

1. **Modo imperativo**: Use "adiciona", "corrige", "refatora" — não "adicionado", "corrigido"
2. **Primeira linha ≤ 72 caracteres**: Facilita leitura em logs compactos
3. **Sem footer de co-autoria do Claude**: Claude não é co-autor
4. **Mensagens genéricas são proibidas**: "update files", "fix bug", "various changes"
5. **Breaking changes**: Se o diff remover/renomear endpoint público, alterar assinatura de função exportada ou mudar schema de banco — use `tipo!:` e adicione footer `BREAKING CHANGE: <descrição do impacto>`
6. **Referências a issues**: Busque padrão `#\d+` ou sequência numérica no nome do branch (ex: `feat/123-login` → `#123`) e no diff. Se encontrada, adicione footer `Refs: #123`

### Atomicidade

Um diff é **não-atômico** se qualquer uma dessas condições for verdadeira:
- Toca **mais de 2 diretórios top-level distintos e não relacionados** (ex: `src/` + `infra/` + `docs/`)
- Combina **tipos diferentes de mudança** sem relação direta (ex: nova feature + bug fix + CI)

Se não-atômico, **pare e recomende**:

```
⚠️ Este diff toca múltiplas áreas não relacionadas:
  - Refactor de autenticação
  - Nova API de usuários
  - Mudança de workflow CI

Recomendo dividir em 3 commits atômicos antes de prosseguir.
Quer que eu o ajude a selecionar qual fazer primeiro?
```

## Casos Especiais

### Repositório Vazio / Commits Iniciais
- Use `feat:` mesmo para commit inicial
- Exemplo: `feat: inicializa projeto com setup base`

### Merge Commits e Revert
- Não use esta skill — use `git merge`, `git revert` nativamente

### Múltiplas Linguagens
- Mesmo propósito → 1 commit
- Refactor por linguagem → múltiplos commits atômicos

## Troubleshooting

| Problema | Solução |
|----------|---------|
| "No changes staged" | Faça `git add .` ou `git add <files>` primeiro |
| "Nothing to commit" | Verifique se há changes com `git status` |
| Diff muito grande | Sugira dividir em commits menores e atômicos |
| Escopo ambíguo | Pergunte ao usuário: "Qual é o módulo/feature principal?" |

## Referências

- Exemplos detalhados: `references/exemplos.md`
- Casos de teste: `evals/evals.json`
- Script helper: `scripts/commit-helper.sh`
