# Exemplos de Commits Conventional

Exemplos em PT-BR, o padrão quando o repositório não tem convenção própria. Se o histórico é em inglês, siga o histórico (ver seção 9).

## 1. Feature (feat)

```
feat(auth): adiciona login com OAuth2 do Google

Implementa o fluxo completo de autenticação via OAuth2,
incluindo troca de código por token e persistência em sessão.

Refs: #142
```

```
feat: implementa cache em memória para consultas repetidas

Estratégia LRU com TTL configurável; reduz a latência de
consultas repetidas em 80%.
```

## 2. Fix (fix)

```
fix(validation): corrige validação de email com '+'

A regex anterior rejeitava endereços válidos como
nome+tag@dominio.com, bloqueando cadastros.

Refs: #89
```

```
fix: evita race condition em atualizações de saldo simultâneas

Duas transações concorrentes podiam ler o mesmo saldo e
sobrescrever uma à outra; o teste E2E de pagamentos reproduzia.
```

## 3. Refactor (refactor)

```
refactor(parser): extrai tokenização para módulo próprio

Reduz a complexidade ciclomática do parser de 12 para 6.
Sem mudança de comportamento.
```

```
refactor: move src/utils para src/lib/utils
```

## 4. Docs (docs)

```
docs(auth): documenta fluxo OAuth2 no README

Inclui variáveis de ambiente necessárias e um exemplo de cliente.
```

```
docs: registra ADR-003 sobre cache em memória
```

## 5. Test (test)

```
test(auth): cobre expiração de sessão

Cobertura do módulo auth sobe de 67% para 89%.
```

## 6. Chore e build (chore, build)

```
chore(deps): atualiza Next.js de 14.0 para 14.1

Ajusta 3 componentes que usavam exports depreciados na 14.1.
```

```
build: troca webpack por Vite no bundle do frontend
```

## 7. Performance (perf)

```
perf(db): adiciona índice em users.created_at

A listagem filtrada por data cai de 2.3s para 80ms.
```

## 8. Breaking change

`!` no título **e** footer `BREAKING CHANGE` descrevendo o impacto para quem consome:

```
feat(api)!: renomeia endpoint /users para /accounts

BREAKING CHANGE: clientes que chamam /users e /users/:id
precisam migrar para /accounts e /accounts/:id.

Refs: #156
```

Atualizar uma dependência que tem breaking change **não** é breaking change do seu projeto, desde que a sua API pública continue igual. Use `chore(deps)` ou `build` e explique os ajustes no corpo.

## 9. Repositório com histórico em inglês

Se o `git log` é em inglês e usa escopos, siga:

```
feat(web): add dark mode toggle to header
```

## 10. Workaround para bug externo

```
fix(csp): define nonce manual no header Content-Security-Policy

Workaround para vercel/next.js#58843: o nonce gerado
automaticamente não chega aos scripts inline.
```

---

## Padrões ruins (evitar)

| Mensagem | Problema |
|---|---|
| `update files` | Sem tipo, sem escopo, sem propósito |
| `fix bug` | Qual bug? Onde? |
| `WIP: doing stuff` | Commit só de mudança pronta |
| `HOTFIX: critical urgente!!!` | Use `fix:` e explique a urgência no corpo |
| `feat(auth): adicionado login` | Particípio; use o imperativo |
| `feat(api): renomeia /users` sem `!` e sem footer | Breaking change escondido |
| `feat: oauth2 google` + `Refs: #2` | O `2` de `oauth2` não é issue |

---

## Checklist de atomicidade

- [ ] O commit faz **uma coisa** bem definida?
- [ ] Pode ser revertido sem quebrar outra coisa?
- [ ] A mensagem explica o **porquê**, não o como?

---

## Escopos comuns

Nomes de módulo ou área, nunca nomes de tipo (`ci`, `docs`, `build`, `test` são tipos, não escopos). Se o histórico já usa outros escopos, eles vencem esta lista.

| Escopo | Uso |
|---|---|
| `auth` | Autenticação e autorização |
| `api` | APIs REST/GraphQL |
| `db` | Schema, migrations, queries |
| `ui` | Componentes, layout |
| `validation` | Schemas, regras de validação |
| `config` | Configuração, variáveis de ambiente |
| `deps` | Dependências (com `chore` ou `build`) |
