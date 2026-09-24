# commit-conventional

Agent Skill que faz o coding agent criar commits com mensagens **Conventional Commits**, com histórico limpo e atômico. A mensagem segue o idioma e a convenção que o repositório já usa; sem convenção detectável, sai em **português (PT-BR)**.

A premissa: coding agents commitam rápido demais. Sem freio, geram "update files", fazem `git add -A` e levam um `.env` junto, misturam refactor, feature e CI no mesmo commit, ignoram a convenção que o repositório já usa, esquecem o `BREAKING CHANGE` quando renomeiam um endpoint público e enchem o corpo da mensagem de justificativas que ninguém deu. Esta skill força o agente a ler o diff real, seguir a convenção do repositório e parar quando o commit não é seguro ou não é atômico.

Exemplo: num repositório em que o diff renomeia o endpoint `/users` para `/accounts`, o pedido "faz o commit" gera:

```
feat!: renomeia rotas de /users para /accounts

Substitui o router de usuários por um router de contas e atualiza o
servidor, o cliente e a documentação da API.

BREAKING CHANGE: os endpoints GET /users e GET /users/:id foram
removidos; use GET /accounts e GET /accounts/:id. No cliente,
listUsers e getUser passam a se chamar listAccounts e getAccount.
```

A skill segue o formato aberto [Agent Skills](https://agentskills.io/specification), então deve funcionar sem modificação em **Claude Code, OpenAI Codex, OpenCode, Cursor, Gemini CLI e GitHub Copilot**. Os evals foram rodados no Claude Code; nas outras ferramentas ela não foi testada. O que muda entre elas é o diretório de instalação e a forma de invocar.

## O que ela faz

- **Lê o diff real**, incluindo arquivos novos (untracked), e evita lockfiles e arquivos gerados em diffs grandes.
- **Segue a convenção do repositório**: `commitlint` (`type-enum`, `scope-enum`…), idioma do histórico (mesmo quando ele não segue Conventional Commits), escopos, formato de ticket. Sem convenção detectável, usa PT-BR.
- **Aplica a spec**: tipo correto (`feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, `style`, `revert`), escopo do módulo dominante, modo imperativo, título medido antes do commit (até 72 caracteres ou o limite do commitlint) e corpo quebrado em 72 colunas.
- **Não inventa**: o corpo só afirma o que está no diff ou no pedido. Sem um porquê informado, a mensagem fica curta em vez de ganhar uma causa ou motivação deduzida.
- **Detecta breaking changes** (endpoint renomeado, assinatura exportada, schema de banco) e usa `tipo!:` com footer `BREAKING CHANGE:`.
- **Referencia issues só com evidência clara** (`#123` ou `123-` no branch, ou citada pelo usuário); `oauth2` não vira `Refs: #2`.
- **Stage seguro**: adiciona arquivos por nome, nunca `git add -A`; deixa `.env`, chaves e artefatos de build de fora e avisa; pergunta a estratégia quando há staged e unstaged misturados; com stage parcial, escreve a mensagem a partir do diff staged.
- **Procura segredos no conteúdo**: antes de commitar, varre o diff staged atrás de chaves (`sk_live_`, `AKIA…`, `ghp_…`, chave privada) e para se encontrar alguma.
- **Diff não atômico**: propõe um plano de divisão (arquivos e mensagem de cada commit) e executa depois da aprovação; se um commit falha no meio, para e informa o que foi feito e o que falta.
- **Respeita hooks**: nunca usa `--no-verify`; se o pre-commit falha, mostra o erro e propõe a correção; se o `commit-msg` (commitlint) rejeita a mensagem, corrige a própria mensagem e tenta de novo uma vez.
- **Para no commit local**: nunca faz `git push` sem pedido explícito, nem adiciona footer de co-autoria do agente, mesmo que o ambiente do agente peça.
- **Mostra a mensagem final completa** e commita com heredoc, para que corpo e footers saiam corretos. Candidatos alternativos só quando tipo ou escopo são ambíguos.

## Instalação

### Via instalador (recomendado)

O [skills CLI](https://github.com/vercel-labs/skills) detecta as ferramentas instaladas na máquina e instala a skill no diretório de cada uma (por symlink; use `--copy` para copiar):

```bash
# instala em todos os agentes detectados, no projeto atual
npx skills add alexandrejunqueira/commit-conventional

# só para alguns agentes, ou globalmente (-g)
npx skills add alexandrejunqueira/commit-conventional -a codex -a opencode -g
```

Alternativa com o GitHub CLI (`gh skill`, em preview). O escopo padrão é `project`; no modo interativo ele pergunta o destino, e fora dele o padrão é o GitHub Copilot:

```bash
# Claude Code, disponível em qualquer projeto
gh skill install alexandrejunqueira/commit-conventional --agent claude-code --scope user

# fixado numa versão (tag)
gh skill install alexandrejunqueira/commit-conventional --pin v2.3.1
```

A partir de um clone local, aponte para a pasta da skill:

```bash
npx skills add ./skills/commit-conventional -g
```

### Manual

Coloque a pasta `skills/commit-conventional` no diretório que a sua ferramenta lê. Global vale em qualquer projeto; projeto vale só naquele repositório.

| Ferramenta | Global | Projeto |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| OpenAI Codex | `~/.agents/skills/` ou `~/.codex/skills/` | `.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` ou `~/.agents/skills/` | `.opencode/skills/` ou `.agents/skills/` |
| Cursor | `~/.cursor/skills/` ou `~/.agents/skills/` | `.cursor/skills/` ou `.agents/skills/` |
| Gemini CLI | `~/.gemini/skills/` ou `~/.agents/skills/` | `.gemini/skills/` ou `.agents/skills/` |
| GitHub Copilot | `~/.copilot/skills/` ou `~/.agents/skills/` | `.github/skills/` ou `.agents/skills/` |

`~/.agents/skills/` é lido por todas as ferramentas acima exceto o Claude Code. Um symlink `~/.claude/skills -> ~/.agents/skills` resolve isso e deixa um único diretório de skills na máquina. Este repositório usa o mesmo truque em nível de projeto: `.agents/skills/commit-conventional` e `.claude/skills/commit-conventional` são symlinks para `skills/commit-conventional`.

A partir de um clone, prefira um symlink a uma cópia: o symlink acompanha cada `git pull`, e a cópia fica parada na versão em que foi feita.

```bash
# exemplo: instalação global manual para Claude Code, a partir de um clone
ln -s "$(pwd)/skills/commit-conventional" ~/.claude/skills/commit-conventional
```

### Atualização

- Instalada pelo skills CLI: `npx skills update commit-conventional` (`-g` para a global).
- Instalada pelo GitHub CLI: `gh skill update`.
- Instalada por symlink para um clone: `git pull` no clone.
- Instalada por cópia: copie de novo; a cópia não se atualiza sozinha.

A versão instalada está no campo `metadata.version` do `SKILL.md`.

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
      historico-ingles-livre/ # histórico em inglês fora do Conventional Commits, com mudança pendente
      commit-msg-hook/        # monorepo com commitlint no hook, escopos calculados de packages/
      plano-falha/            # 3 commits em ordem fixa, o do meio barrado pelo pre-commit
      sem-push/               # branch com upstream configurado
```

`evals/` é usado pelo [skill-creator](https://github.com/anthropics/skills) e ignorado pelas demais ferramentas. `.claude-plugin/plugin.json` na raiz do repositório existe para o marketplace de plugins do Claude Code e serve de manifesto para o skills CLI; também é ignorado pelas outras ferramentas.

## Compatibilidade

- O frontmatter do `SKILL.md` usa apenas campos do spec (`name`, `description`, `license`, `compatibility`, `metadata`). Nenhum campo exclusivo de uma ferramenta.
- O corpo não depende de tool, hook, servidor MCP, slash command ou script próprio. Precisa de um agente que execute comandos no terminal: `git`, e `grep`, `wc` e `printf` para a varredura de segredos e a medição do título. Todos existem por padrão no macOS e no Linux; no Windows, use o Git Bash ou o WSL.
- As referências a `references/` e `evals/` são caminhos relativos à raiz da skill, como o spec pede.

## Evals

Os casos em `evals/evals.json` seguem o schema do [skill-creator](https://github.com/anthropics/skills), com expectativas semânticas avaliadas por um juiz (LLM ou humano).

- **Casos 0 a 9 e 22** descrevem o diff no próprio prompt e medem a escolha da mensagem: tipo, escopo, modo imperativo, corpo, footers. Os casos 5, 7 e 22 também verificam se o corpo inventa algo que o pedido não disse.
- **Casos 13 e 26** medem ativação negativa: uma pergunta conceitual ou uma consulta ao histórico não deve disparar commit. O 26 roda num repositório com mudanças pendentes, para tentar o agente.
- **Casos 10 a 12, 14 a 21 e 23 a 26** usam fixtures em `evals/files/` e medem o comportamento no git. Como um `.git` aninhado não pode ser versionado, cada fixture é um `setup.sh` que monta um repositório descartável:

```bash
bash skills/commit-conventional/evals/files/atomicidade/setup.sh /tmp/repo-atomicidade
```

Depois da execução, o juiz confere o estado do repositório (`git log`, `git status`): se houve commit, o que foi para stage e com qual mensagem.

### Como rodar

Com o skill-creator instalado, peça ao agente para rodar os evals da skill. O modo mais útil é comparar duas versões: o skill-creator roda cada caso com a versão nova e com a anterior (um snapshot de uma tag ou commit), em agentes separados, e mostra o resultado lado a lado. Uma execução por caso é pouco para diferenças pequenas; use 3 nos casos que a mudança afeta.

Cuidados que aprendemos rodando:

- Monte os repositórios de teste fora de qualquer repositório git, para que um agente de teste não commite no projeto de verdade.
- Dê a cada agente de teste o caminho do `SKILL.md` da versão sendo testada e proíba o uso da skill instalada, que pode ser outra versão.

### Limites conhecidos

- Os casos 11, 12, 22 e 25 passaram igual nas versões 2.0.0 e 2.2.0: o modelo já faz o certo sem as regras que eles cobrem. Servem para pegar regressão, não para mostrar ganho de uma versão.
- O caso 23 não consegue exercitar a correção após rejeição do hook `commit-msg`: o agente lê a regra do commitlint antes de commitar e acerta de primeira.
- O juiz lê um resumo dos comandos escrito pelo próprio agente, não um log real; verificações como "não usou `--no-verify`" dependem desse resumo e do estado final do repositório.

## Versões

As versões são tags git (`vX.Y.Z`); o número também está em `metadata.version` no `SKILL.md` e em `.claude-plugin/plugin.json`.

- **2.3.1**: o corpo só afirma o que está no diff ou no pedido; o tamanho do título é informado em bytes.
- **2.3.0**: enxuga regras que não mudaram o resultado nos benchmarks (push, hook `commit-msg`, falha no meio do plano, consulta ao histórico).
- **2.2.0**: título medido antes do commit, corpo em 72 colunas, hook `commit-msg`, parada limpa quando um commit do plano falha, sem push.
- **2.1.0**: mensagem a partir do diff staged com stage parcial, varredura de segredos no conteúdo, idioma do histórico mesmo fora do Conventional Commits.
- **2.0.0**: segue a convenção do repositório (commitlint, idioma, escopos), stage por nome, recusa de arquivos sensíveis, divisão de diffs não atômicos com aprovação.

## Licença

MIT. Veja `LICENSE`.
