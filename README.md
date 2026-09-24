# commit-conventional

Agent Skill que faz o coding agent criar commits com mensagens **Conventional Commits em português**, com histórico limpo e atômico.

A premissa: coding agents commitam rápido demais. Sem freio, geram "update files", fazem `git add -A` e levam um `.env` junto, misturam refactor, feature e CI no mesmo commit, ignoram a convenção que o repositório já usa e esquecem o `BREAKING CHANGE` quando renomeiam um endpoint público. Esta skill força o agente a ler o diff real, seguir a convenção do repositório e parar quando o commit não é seguro ou não é atômico.

A skill segue o formato aberto [Agent Skills](https://agentskills.io/specification) e funciona sem modificação em **Claude Code, OpenAI Codex, OpenCode, Cursor, Gemini CLI e GitHub Copilot**. O que muda entre ferramentas é só o diretório de instalação e a forma de invocar.

## O que ela faz

- **Lê o diff real**, incluindo arquivos novos (untracked), e evita lockfiles e arquivos gerados em diffs grandes.
- **Segue a convenção do repositório**: `commitlint` (`type-enum`, `scope-enum`…), idioma do histórico (mesmo quando ele não segue Conventional Commits), escopos, formato de ticket. Sem convenção detectável, usa PT-BR.
- **Aplica a spec**: tipo correto (`feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, `style`, `revert`), escopo do módulo dominante, modo imperativo, título medido antes do commit (até 72 caracteres ou o limite do commitlint) e corpo quebrado em 72 colunas.
- **Detecta breaking changes** (endpoint renomeado, assinatura exportada, schema de banco) e usa `tipo!:` com footer `BREAKING CHANGE:`.
- **Referencia issues só com evidência clara** (`#123` ou `123-` no branch, ou citada pelo usuário); `oauth2` não vira `Refs: #2`.
- **Stage seguro**: adiciona arquivos por nome, nunca `git add -A`; deixa `.env`, chaves e artefatos de build de fora e avisa; pergunta a estratégia quando há staged e unstaged misturados; com stage parcial, escreve a mensagem a partir do diff staged.
- **Procura segredos no conteúdo**: antes de commitar, varre o diff staged atrás de chaves (`sk_live_`, `AKIA…`, `ghp_…`, chave privada) e para se encontrar alguma.
- **Diff não atômico**: propõe um plano de divisão (arquivos e mensagem de cada commit) e executa depois da aprovação; se um commit falha no meio, para e informa o que foi feito e o que falta.
- **Respeita hooks**: nunca usa `--no-verify`; se o pre-commit falha, mostra o erro e propõe a correção; se o `commit-msg` (commitlint) rejeita a mensagem, corrige a própria mensagem e tenta de novo uma vez.
- **Para no commit local**: nunca faz `git push` sem pedido explícito, nem adiciona footer de co-autoria do agente.
- **Mostra a mensagem final completa** e commita com heredoc, para que corpo e footers saiam corretos. Candidatos alternativos só quando tipo ou escopo são ambíguos.

## Instalação

### Via instalador (recomendado)

O [skills CLI](https://github.com/vercel-labs/skills) detecta as ferramentas instaladas na máquina e copia a skill para o diretório de cada uma:

```bash
# instala em todos os agentes detectados, no projeto atual
npx skills add alexandrejunqueira/commit-conventional

# só para alguns agentes, ou globalmente (-g)
npx skills add alexandrejunqueira/commit-conventional -a codex -a opencode -g
```

Alternativa com o GitHub CLI (`--agent` escolhe o destino; o padrão é Copilot):

```bash
gh skill install alexandrejunqueira/commit-conventional
```

A partir de um clone local, aponte para a pasta da skill:

```bash
npx skills add ./skills/commit-conventional -g
```

### Manual

Copie a pasta `skills/commit-conventional` para o diretório que a sua ferramenta lê. Global vale em qualquer projeto; projeto vale só naquele repositório.

| Ferramenta | Global | Projeto |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| OpenAI Codex | `~/.agents/skills/` ou `~/.codex/skills/` | `.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` ou `~/.agents/skills/` | `.opencode/skills/` ou `.agents/skills/` |
| Cursor | `~/.cursor/skills/` ou `~/.agents/skills/` | `.cursor/skills/` ou `.agents/skills/` |
| Gemini CLI | `~/.gemini/skills/` ou `~/.agents/skills/` | `.gemini/skills/` ou `.agents/skills/` |
| GitHub Copilot | `~/.copilot/skills/` ou `~/.agents/skills/` | `.github/skills/` ou `.agents/skills/` |

`~/.agents/skills/` é lido por todas as ferramentas acima exceto o Claude Code. Um symlink `~/.claude/skills -> ~/.agents/skills` resolve isso e deixa um único diretório de skills na máquina. Este repositório usa o mesmo truque em nível de projeto: `.agents/skills/commit-conventional` e `.claude/skills/commit-conventional` são symlinks para `skills/commit-conventional`.

```bash
# exemplo: instalação global manual para Claude Code
cp -r skills/commit-conventional ~/.claude/skills/
```

### Como invocar

Em todas as ferramentas a skill é ativada automaticamente quando o pedido bate com a `description` ("commit", "commita isso", "fazer commit das mudanças" etc.). Para forçar:

| Ferramenta | Invocação explícita |
|---|---|
| Claude Code | `/commit-conventional` |
| OpenAI Codex | `$commit-conventional` |
| Cursor | `/commit-conventional` |
| OpenCode | o agente chama o tool `skill` com o nome |
| Gemini CLI | o agente chama `activate_skill`; pede consentimento na primeira ativação |
| GitHub Copilot | automática pela `description` |

## Estrutura

```
skills/commit-conventional/
  SKILL.md                    # fluxo: contexto, pré-condições, convenção, stage, atomicidade, mensagem, commit
  references/
    exemplos.md               # exemplos por tipo, breaking change, anti-padrões
  evals/
    evals.json                # 27 casos, expectativas semânticas
    files/                    # fixtures: cada setup.sh monta um repositório git descartável
      atomicidade/            # refactor + feature + CI no mesmo diff
      staging-misto/          # staged e unstaged misturados
      breaking-change/        # endpoint /users renomeado para /accounts
      arquivo-sensivel/       # .env com segredo fora do .gitignore
      hook-falha/             # pre-commit que rejeita console.log
      commit-inicial/         # repositório sem nenhum commit
      branch-oauth2/          # número dentro de palavra no nome do branch
      historico-ingles/       # histórico em inglês + commitlint com scope-enum
      stage-parcial/          # arquivo com parte staged e parte não
      segredo-no-codigo/      # chave de API escrita direto no código
      historico-ingles-livre/ # histórico em inglês fora do Conventional Commits
      commit-msg-hook/        # commitlint no hook commit-msg, regra de escopo num config compartilhado
      plano-falha/            # 3 commits em ordem fixa, o do meio barrado pelo pre-commit
      sem-push/               # branch com upstream configurado
```

`evals/` é usado pelo [skill-creator](https://github.com/anthropics/skills) e ignorado pelas demais ferramentas. `.claude-plugin/plugin.json` na raiz do repositório existe para o marketplace de plugins do Claude Code e serve de manifesto para o skills CLI; também é ignorado pelas outras ferramentas.

## Compatibilidade

- O frontmatter do `SKILL.md` usa apenas campos do spec (`name`, `description`, `license`, `compatibility`, `metadata`). Nenhum campo exclusivo de uma ferramenta.
- O corpo não depende de tool, hook, servidor MCP, slash command ou script próprio. Só precisa de um agente que execute comandos `git` no terminal, o que todas as ferramentas listadas fazem. As referências a `references/` e `evals/` são caminhos relativos à raiz da skill, como o spec pede.

## Evals

Os casos em `evals/evals.json` seguem o schema do [skill-creator](https://github.com/anthropics/skills), com expectativas semânticas avaliadas por um juiz (LLM ou humano).

- **Casos 0 a 9 e 22** descrevem o diff no próprio prompt e medem a escolha da mensagem: tipo, escopo, modo imperativo, corpo, footers.
- **Casos 13 e 26** medem ativação negativa: uma pergunta conceitual ou uma consulta ao histórico não deve disparar commit.
- **Casos 10 a 12, 14 a 21 e 23 a 25** usam fixtures em `evals/files/` e medem o comportamento no git. Como um `.git` aninhado não pode ser versionado, cada fixture é um `setup.sh` que monta um repositório descartável:

```bash
bash skills/commit-conventional/evals/files/atomicidade/setup.sh /tmp/repo-atomicidade
```

Depois da execução, o juiz confere o estado do repositório (`git log`, `git status`): se houve commit, o que foi para stage e com qual mensagem.

## Licença

MIT. Veja `LICENSE`.
