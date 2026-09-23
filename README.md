# commit-conventional

Agent Skill que faz o coding agent criar commits com mensagens **Conventional Commits em português**, com histórico limpo e atômico.

A premissa: coding agents commitam rápido demais. Sem freio, geram "update files", misturam refactor, feature e CI no mesmo commit e esquecem o `BREAKING CHANGE` quando renomeiam um endpoint público. Esta skill força o agente a ler o diff real, comparar 3 candidatos de mensagem e parar quando o diff não é atômico.

A skill segue o formato aberto [Agent Skills](https://agentskills.io/specification) e funciona sem modificação em **Claude Code, OpenAI Codex, OpenCode, Cursor, Gemini CLI e GitHub Copilot**. O que muda entre ferramentas é só o diretório de instalação e a forma de invocar.

## O que ela faz

- **Analisa o diff** (branch, últimos commits, staged e unstaged) antes de propor qualquer mensagem.
- **Gera 3 candidatos** (literal, impacto, intenção) e escolhe o melhor com uma justificativa curta.
- **Aplica a spec**: tipo correto (`feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `ci`, `style`), escopo quando mais de 70% dos arquivos são do mesmo módulo, modo imperativo, primeira linha com até 72 caracteres.
- **Detecta breaking changes** (endpoint renomeado, assinatura exportada, schema de banco) e usa `tipo!:` com footer `BREAKING CHANGE:`.
- **Referencia issues** encontradas no nome do branch ou no diff com `Refs: #123`.
- **Para quando o diff não é atômico** e recomenda dividir em commits separados.
- **Respeita o stage**: se há mudanças staged e unstaged misturadas, pergunta a estratégia em vez de decidir sozinha.

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
  SKILL.md                    # instruções principais: fluxo, spec, heurísticas, atomicidade
  references/
    exemplos.md               # exemplos detalhados por tipo de commit
  scripts/
    commit-helper.sh          # coleta branch, commits recentes, staged/unstaged e tamanho do diff
  evals/
    evals.json                # 13 casos, expectativas semânticas
    files/
      atomicidade/            # fixture: refactor + feature + CI no mesmo diff
      staging-misto/          # fixture: staged e unstaged misturados
      breaking-change/        # fixture: endpoint /users renomeado para /accounts
```

`evals/` é usado pelo [skill-creator](https://github.com/anthropics/skills) e ignorado pelas demais ferramentas. `.claude-plugin/plugin.json` na raiz do repositório existe para o marketplace de plugins do Claude Code e serve de manifesto para o skills CLI; também é ignorado pelas outras ferramentas.

## Compatibilidade

- O frontmatter do `SKILL.md` usa apenas campos do spec (`name`, `description`, `license`, `compatibility`, `metadata`). Nenhum campo exclusivo de uma ferramenta.
- O corpo não depende de tool, hook, servidor MCP ou slash command. Só precisa de um agente que execute comandos `git` no terminal, o que todas as ferramentas listadas fazem. As referências a `references/`, `scripts/` e `evals/` são caminhos relativos à raiz da skill, como o spec pede.
- `scripts/commit-helper.sh` requer Bash. É opcional: o agente pode coletar o mesmo contexto com `git status`, `git log` e `git diff`.

## Evals

Os casos em `evals/evals.json` seguem o schema do [skill-creator](https://github.com/anthropics/skills), com expectativas semânticas avaliadas por um juiz (LLM ou humano).

- **Casos 0 a 9** descrevem o diff no próprio prompt e medem a escolha da mensagem: tipo, escopo, modo imperativo, corpo, footers.
- **Casos 10 a 12** usam fixtures em `evals/files/` e medem o comportamento no git. Como um `.git` aninhado não pode ser versionado, cada fixture é um `setup.sh` que monta um repositório descartável:

```bash
bash skills/commit-conventional/evals/files/atomicidade/setup.sh /tmp/repo-atomicidade
```

Depois da execução, o juiz confere o estado do repositório (`git log`, `git status`): se houve commit, o que foi para stage e com qual mensagem.

## Licença

MIT. Veja `LICENSE`.
