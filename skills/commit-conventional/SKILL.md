---
name: commit-conventional
description: Cria commits Git com mensagens Conventional Commits. Ative quando o usuário pedir para commitar mudanças, com frases como "commit", "commita isso", "faz o commit", "fazer commit das mudanças" ou "commit this". Lê o diff real, segue a convenção do próprio repositório (idioma, escopos, commitlint), faz stage só dos arquivos relevantes, recusa arquivos sensíveis, detecta diffs não atômicos e propõe como dividi-los. Não ative para explicar a spec Conventional Commits, revisar uma mensagem sem commitar, fazer merge, revert ou rebase.
license: MIT
compatibility: Git instalado; repositório Git válido com mudanças a commitar
metadata:
  author: Alexandre Junqueira
  version: "2.0.0"
---

# commit-conventional

Cria commits com mensagens [Conventional Commits](https://www.conventionalcommits.org/) a partir do diff real, respeitando a convenção que o repositório já usa.

## 1. Coletar contexto

Rode, nesta ordem:

```bash
git status                      # branch, merge/rebase em andamento, detached HEAD, untracked
git log --oneline -15           # convenção do histórico (falha em repositório sem commits: é o commit inicial)
git diff --stat HEAD            # tamanho e distribuição da mudança (sem HEAD: git diff --cached --stat)
```

Depois leia o conteúdo:

- `git diff HEAD -- <arquivos>` para arquivos rastreados. Não leia lockfiles (`*.lock`, `package-lock.json`), build (`dist/`, `build/`), arquivos minificados ou gerados, a menos que sejam a mudança inteira.
- Arquivos **untracked** não aparecem no `git diff`. Leia-os diretamente (os listados em `git status` ou `git ls-files --others --exclude-standard`).
- Em diff grande, comece pelo `--stat` e leia os arquivos mais relevantes, não tudo.

Procure também configuração de convenção: `commitlint.config.*`, `.commitlintrc*`, `.czrc`, campo `commitlint` no `package.json`, seção de commits em `CONTRIBUTING.md`.

## 2. Pré-condições (pare e avise se falhar)

- **Merge, rebase, cherry-pick ou revert em andamento** (informado pelo `git status`): não use esta skill; oriente o usuário a concluir a operação com o próprio git.
- **Detached HEAD**: avise e pergunte se deve criar um branch antes.
- **Nada a commitar**: diga isso e pare.

## 3. Descobrir a convenção do repositório

A convenção do repositório vence os padrões desta skill. Em ordem de prioridade:

1. **Config de commitlint/commitizen**: respeite `type-enum`, `scope-enum`, `subject-case`, `header-max-length` e similares.
2. **Histórico** (`git log`), quando a maioria dos commits já segue Conventional Commits:
   - **Idioma**: escreva no idioma predominante. Se o histórico é em inglês, a mensagem é em inglês.
   - **Escopos**: reutilize os escopos existentes em vez de inventar nomes novos. Se o histórico não usa escopo, não use.
   - **Referências**: copie o formato de ticket usado (`Refs: #123`, `Closes #123`, `ABC-123`).
3. **Sem convenção detectável** (repositório novo ou histórico fora do padrão): use os padrões abaixo, com mensagem em **português (PT-BR)**.

## 4. Analisar a mudança

- **Natureza**: que tipo de mudança é (tabela de tipos abaixo).
- **Propósito**: por que foi feita. É isso que vai no corpo.
- **Escopo**: qual módulo ou área foi afetado.
- **Atomicidade**: se a mudança faz uma coisa só (seção 6).
- **Breaking change**: remove ou renomeia endpoint público, muda assinatura de função exportada, altera schema de banco ou formato de config de forma incompatível.

## 5. Stage

Nunca use `git add -A`, `git add .` ou `git commit -a`. Adicione **por nome**: `git add -- <arquivo> ...`.

| Estado | Ação |
|---|---|
| Nada staged | Faça stage dos arquivos relevantes da mudança, incluindo untracked que pertencem a ela |
| Só há mudanças staged | Commite exatamente o que está staged; não adicione nada |
| Staged **e** outras mudanças (unstaged ou untracked) | Pergunte a estratégia: só o staged, incluir tudo, ou dividir. Não altere o stage antes da resposta |

**Arquivos sensíveis ou indevidos** nunca entram por iniciativa da skill: `.env*` (exceto `.env.example`), `*.pem`, `*.key`, `*.p12`, `id_rsa*`, arquivos de credenciais, arquivos com cara de segredo (tokens, chaves de API), binários grandes e artefatos de build fora do `.gitignore`. Deixe-os fora do stage, avise o usuário e sugira adicioná-los ao `.gitignore`. Se o próprio usuário já os colocou no stage, avise e peça confirmação antes de commitar.

## 6. Atomicidade

Um commit deve fazer **uma coisa**. O critério é semântico, não contagem de diretórios:

- **Não atômico**: mudanças independentes que poderiam ser revertidas separadamente. Ex.: refactor de auth + endpoint novo + ajuste de pipeline de CI.
- **Atômico**, mesmo tocando várias pastas: uma feature com seu código, seus testes e sua documentação; um rename com todas as referências atualizadas; um bump de dependência com os ajustes que ele exigiu.

Se não for atômico, **não commite**. Proponha um plano e peça aprovação:

```
⚠️ Estas mudanças fazem 3 coisas independentes. Proposta de divisão:

1. refactor(auth): extrai troca de token para função própria
   src/auth/oauth.ts
2. feat(api): adiciona busca de usuário por id
   src/api/users.ts
3. ci: executa testes antes do build no deploy
   .github/workflows/deploy.yml

Posso commitar nessa ordem?
```

Com a aprovação, faça um commit por grupo (`git add -- <arquivos do grupo>` e commit), na ordem proposta.

**Limite**: se um mesmo arquivo contém mudanças de grupos diferentes, a divisão exige stage por trecho (`git add -p`), que é interativo. Não tente simular. Diga ao usuário qual arquivo mistura as mudanças e ofereça: commitar esse arquivo junto com um dos grupos (explicando no corpo), ou o usuário faz o `git add -p` e a skill commita o resto.

## 7. Escrever a mensagem

```
<tipo>(<escopo opcional>)<! se breaking>: <descrição imperativa>

[corpo opcional: o quê e por quê, não o como]

[footers opcionais: BREAKING CHANGE, referências]
```

### Tipos

| Tipo | Uso |
|---|---|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `docs` | Apenas documentação |
| `style` | Formatação, sem mudança de lógica |
| `refactor` | Reestruturação sem mudar comportamento |
| `perf` | Melhoria de performance |
| `test` | Adiciona ou corrige testes |
| `build` | Sistema de build, bundler, dependências que afetam o build |
| `ci` | Pipelines e configuração de CI/CD |
| `chore` | Manutenção que não se encaixa acima (deps, configs, tarefas) |
| `revert` | Reverte commit anterior (prefira `git revert`) |

### Regras

1. **Descrição no imperativo**: "adiciona", "corrige", "remove" ("add", "fix", "remove" em inglês). Não "adicionado", "adicionando".
2. **Primeira linha com até 72 caracteres**, sem ponto final.
3. **Escopo**: o módulo dominante da mudança, preferindo escopos que já existem no histórico. Omita se a mudança não tem área dominante.
4. **Corpo** quando o porquê não é óbvio pela descrição: workarounds, decisões, números medidos (ex.: "query cai de 2.3s para 80ms"). Não descreva linha a linha o que o diff já mostra.
5. **Breaking change**: `!` antes dos dois-pontos **e** footer `BREAKING CHANGE: <impacto para quem consome>`.
6. **Referências a issues**, só quando houver evidência clara:
   - o usuário citou a issue no pedido;
   - o branch tem `#123`, ou começa com o número após o prefixo (`feat/123-login`, `123-login`), ou tem id de ticket (`feat/ABC-123-login`).
   - Números dentro de palavras **não** são issue: `oauth2`, `v14`, `next14`, `utf8`.
   - Bug de projeto externo vai no corpo com o nome completo (`vercel/next.js#58843`), não como `Refs: #58843`.
7. **Proibido**: mensagens genéricas ("update files", "fix bug", "ajustes", "WIP"), e footer de co-autoria do agente, exceto se a convenção do repositório exigir atribuição de IA.
8. **Commit inicial** (repositório sem commits): `feat: inicializa projeto com <o essencial>`, salvo convenção diferente.

### Quando houver dúvida real

Se o tipo ou o escopo for genuinamente ambíguo (ex.: `fix` ou `refactor`; dois módulos com peso parecido), mostre 2 ou 3 candidatos e justifique a escolha em uma linha. Nos casos claros, vá direto para a mensagem final.

## 8. Commitar

Mostre a mensagem final **completa** (título, corpo e footers) e execute com heredoc, para que corpo e footers saiam em linhas corretas:

```bash
git commit -F - <<'EOF'
fix(auth): renova token antes de expirar

O refresh só acontecia após o 401, e requisições em paralelo
falhavam juntas durante a renovação.

Refs: #214
EOF
```

- Nunca use `--no-verify`, `--amend` ou `--allow-empty` sem pedido explícito.
- **Hook de pre-commit falhou**: mostre o erro, explique a causa e proponha a correção. Não corrija o código do usuário nem tente de novo sem confirmação.
- **Hook reformatou arquivos** (formatter automático): faça stage de novo **só dos mesmos arquivos** e repita o commit uma vez.
- Depois do commit, mostre `git log --oneline -1` e o `git status` resumido, deixando claro o que ficou fora do commit.

## Referências

- Exemplos por tipo, breaking change e anti-padrões: `references/exemplos.md`
- Casos de teste: `evals/evals.json`
