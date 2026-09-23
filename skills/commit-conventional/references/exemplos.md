# Exemplos de Commits Conventional

## 1. Feature (feat)

```
feat(auth): adiciona login com OAuth2 Google

Implementa fluxo completo de autenticação via OAuth2,
incluindo troca de código por token e persistência em sessão.

Refs: #142
```

```
feat: implementa sistema de cache em memória

Adiciona estratégia LRU de cache com TTL configurável,
reduzindo latência de queries repetidas em 80%.
```

## 2. Fix (fix)

```
fix(validation): corrige regex de validação de email

A regex anterior aceitava emails inválidos com múltiplos @.
Nova implementação usa RFC 5322 simplificado.

Refs: #89
```

```
fix: evita race condition em transações simultâneas

Adiciona lock pessimista em atualização de saldo,
prevenindo condição de corrida identificada em teste E2E.
```

## 3. Refactor (refactor)

```
refactor(parser): extrai lógica de tokenização em módulo próprio

Move tokenização de `parser.js` para `tokenizer.js`,
reduzindo complexidade ciclomática de 12 para 6.

Sem mudança de comportamento. Todos os testes passam.
```

```
refactor: migra arquivos de src/utils para src/lib/utils

Reorganiza estrutura de diretórios para melhor escalabilidade.
Atualiza 23 imports em toda a aplicação.
```

## 4. Docs (docs)

```
docs(api): adiciona seção de autenticação no README

Documenta fluxo de OAuth2, variáveis de ambiente necessárias
e exemplo de cliente Python.
```

```
docs: escreve ADR-003 sobre decisão de cache em memória

Registra trade-offs entre Redis vs cache local.
```

## 5. Test (test)

```
test(auth): adiciona testes de timeout de sessão

Cobertura sobe de 67% para 89% em módulo auth.
```

## 6. Chore (chore)

```
chore(deps): atualiza Next.js de 14.0 para 14.1

Inclui breaking change: exports no App Router.
Atualiza 3 componentes que usavam exports deprecados.
```

## 7. Performance (perf)

```
perf(db): adiciona índice em coluna created_at

Queries de filtro por data sobem de 2.3s para 80ms.
```

## 8. Breaking Change

```
feat(api): renomeia endpoint /users para /people

BREAKING CHANGE: clients usando /users precisam atualizar
para /people. Estrutura de resposta também mudou.

Refs: #156
```

---

## Padrões Ruins (Evitar)

❌ `update files` — sem tipo, sem escopo, sem contexto
❌ `fix bug` — qual bug? qual escopo?
❌ `WIP: doing stuff` — commit apenas de mudanças prontas
❌ `HOTFIX: critical urgente!!!` — use `fix:` com contexto no corpo

---

## Checklist de Atomicidade

- [ ] Este commit faz **uma coisa** bem definida?
- [ ] Poderia ser revertido sem quebrar outra coisa?
- [ ] Os testes passam após este commit?
- [ ] A mensagem explica o **por quê**, não o **como**?

---

## Escopos Comuns em Monorepos (Pulsar)

| Escopo | Uso |
|--------|-----|
| `auth` | Autenticação e autorização |
| `api` | APIs REST/GraphQL |
| `db` | Schema, migrations, queries |
| `ui` | Componentes React, layout |
| `validation` | Schemas, regras de validação |
| `config` | Configuração, env vars |
| `ci` | GitHub Actions, deploy |
| `docs` | Documentação, ADRs |
| `deps` | Dependências |
| `build` | Build process, bundler |
