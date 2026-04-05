# Design Document: goal-crud

## Overview

Esta feature implementa o CRUD completo do objeto **Goal** (GTD Horizonte 3) no `lowbit-planner`.

Goals são metas de 1-2 anos que ficam acima de Projects (H1) e Areas (H2) na hierarquia GTD. O arquivo `libs/objects/goal.sh` já existe mas usa convenções antigas (camelCase, tabela `goal` inexistente, sem uso de `generic_*`, `log_print`, `validate_*`). Esta feature refatora completamente esse módulo e adiciona a tabela `goals` ao banco de dados, seguindo os padrões estabelecidos pelos módulos `area.sh`, `project.sh` e `task.sh`.

A hierarquia de objetos no sistema é:

```
Horizon 5: Principle / Purpose
Horizon 4: Vision
Horizon 3: Goal        ← esta feature
Horizon 2: Area
Horizon 1: Project
Ground:    Task / Inbox
```

Um Goal pode opcionalmente pertencer a uma Area e pode ter Projects vinculados a ele via `projects.goal_id`.

---

## Architecture

O sistema segue uma arquitetura de shell scripts modular:

```
plan.sh                        ← entry point, despacha para goal_main
  └── libs/objects/goal.sh     ← Goal_Module (refatorado)
        ├── goal_add
        ├── goal_delete
        ├── goal_edit
        ├── goal_list
        ├── goal_search
        ├── goal_start
        ├── goal_stop
        ├── goal_complete
        └── goal_main

libs/database/database_init.sql ← DDL: tabela goals + view goals_view
libs/objects/generic.sh         ← generic_add, generic_list, generic_set_property
libs/utils/validate.sh          ← validate_database_id, validate_date
libs/utils/log.sh               ← log_print
libs/utils/help.sh              ← help_print_goal, help_print_goal_add
libs/objects/project.sh         ← project_edit atualizado para --goal por nome
```

O fluxo de uma operação típica:

```
plan goal add "Aprender Rust" --area "Personal" --due-date 2026-12-31
  → plan.sh: goal_main "add" "Aprender Rust" "--area" "Personal" ...
    → goal_add: parse args → resolve area_id → validate_date → generic_add
      → database_run INSERT INTO goals ...
```

---

## Components and Interfaces

### goal_main

Ponto de entrada do módulo. Despacha subcomandos via `case`:

```
goal_main [SUBCOMMAND] [ARGS...]
  add       → goal_add
  complete  → goal_complete
  delete    → goal_delete
  edit      → goal_edit
  list      → goal_list
  search    → goal_search
  start     → goal_start
  stop      → goal_stop
  help / *  → help_get_message goal
```

### goal_add

```
goal_add GOAL_NAME [--area AREA_NAME] [--start-date YYYY-MM-DD] [--due-date YYYY-MM-DD]
```

- Arg posicional: `GOAL_NAME` (obrigatório)
- Resolve `AREA_NAME` → `area_id` via `SELECT id FROM areas WHERE name = '...'`
- Valida datas via `validate_date`
- Insere via `generic_add "goals" FIELDS VALUES GOAL_NAME`

### goal_delete

```
goal_delete GOAL_ID
```

- Valida ID via `validate_database_id goals GOAL_ID`
- Busca nome para confirmação
- Solicita confirmação via `log_print user`
- Executa `DELETE FROM goals WHERE id = GOAL_ID`

### goal_edit

```
goal_edit GOAL_ID [--name NEW_NAME] [--area AREA_NAME] [--start-date DATE] [--due-date DATE]
```

- Valida ID via `validate_database_id`
- Cada flag atualiza via `generic_set_property goals id GOAL_ID FIELD VALUE`
- `--area` resolve nome → id antes de atualizar

### goal_list

```
goal_list
```

- Chama `generic_list goals_view`

### goal_search

```
goal_search PATTERN
```

- Executa `SELECT * FROM goals_view WHERE name LIKE '%PATTERN%'`

### goal_start / goal_stop / goal_complete

```
goal_start GOAL_ID   → status = 'In Progress'
goal_stop  GOAL_ID   → status = 'Pending'
goal_complete GOAL_ID → status = 'Done' + completed_at = DATE('now','localtime')
```

Todos validam ID via `validate_database_id` e atualizam via `generic_set_property`.

### help_print_goal / help_print_goal_add

Funções adicionadas em `libs/utils/help.sh` seguindo o padrão das demais (`help_print_area`, `help_print_project`).

### project_edit — atualização para --goal por nome

O flag `--goal` em `project_edit` atualmente aceita um ID diretamente. Conforme decisão do usuário, deve passar a aceitar `GOAL_NAME`, resolvendo para `goal_id` via `SELECT id FROM goals WHERE name = '...'` — mesmo padrão do `--area`.

---

## Data Models

### Tabela `goals` (nova)

```sql
CREATE TABLE goals (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL UNIQUE,
  area_id      INTEGER,
  vision_id    INTEGER,
  status       TEXT NOT NULL DEFAULT 'Pending',
  ranking      INTEGER DEFAULT 0,
  start_date   TEXT,
  due_date     TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  FOREIGN KEY (area_id) REFERENCES areas (id)
);
```

- `area_id`: nullable — Goal pode existir sem Area
- `vision_id`: nullable — FK para futura tabela `visions` (mesmo padrão de `goal_id` em `projects`)
- `status`: `'Pending'` | `'In Progress'` | `'Done'`

### View `goals_view` (nova)

```sql
CREATE VIEW goals_view AS
SELECT
  goals.id         AS id,
  goals.name       AS name,
  areas.name       AS area,
  goals.status     AS status,
  goals.start_date AS start_date,
  goals.due_date   AS due_date,
  goals.ranking    AS ranking
FROM goals
LEFT JOIN areas ON goals.area_id = areas.id;
```

### Tabela `projects` (atualização da view)

A `projects_view` precisa incluir a coluna `goal` (nome da Goal via LEFT JOIN) para exibição:

```sql
CREATE VIEW projects_view AS
SELECT
  projects.id         AS id,
  projects.name       AS name,
  areas.name          AS area,
  goals.name          AS goal,
  projects.status     AS status,
  projects.start_date AS start_date,
  projects.due_date   AS due_date,
  projects.ranking    AS ranking
FROM projects
LEFT JOIN areas ON projects.area_id = areas.id
LEFT JOIN goals ON projects.goal_id = goals.id;
```

### Relacionamentos

```
areas (id) ←── goals.area_id        (nullable)
goals (id) ←── projects.goal_id     (nullable, já existe)
visions(id)←── goals.vision_id      (nullable, FK futura)
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Goal add round trip

*For any* valid goal name, after inserting via `goal_add`, querying `goals_view` by that name should return exactly one record with the same name and status `'Pending'`.

**Validates: Requirements 2.1, 2.7**

---

### Property 2: Area resolution on add

*For any* existing area name passed via `--area`, the inserted goal's `area_id` should equal the `id` of that area in the `areas` table.

**Validates: Requirements 2.2**

---

### Property 3: Invalid area rejected on add

*For any* area name that does not exist in the `areas` table, `goal_add` should exit with error and the `goals` table should remain unchanged.

**Validates: Requirements 2.3, 5.4**

---

### Property 4: Date validation rejects invalid formats

*For any* string that does not match `YYYY-MM-DD`, passing it as `--start-date` or `--due-date` should cause `goal_add` and `goal_edit` to exit with error without modifying the database.

**Validates: Requirements 2.4, 2.5, 5.5, 5.6**

---

### Property 5: Status lifecycle transitions

*For any* goal in the database, applying `goal_start` sets status to `'In Progress'`, `goal_stop` sets to `'Pending'`, and `goal_complete` sets to `'Done'` with a non-null `completed_at`.

**Validates: Requirements 6.2, 7.2, 8.2, 8.3**

---

### Property 6: Delete removes goal

*For any* existing goal ID, after `goal_delete` is confirmed, querying `goals` by that ID should return no rows.

**Validates: Requirements 4.3**

---

### Property 7: Search returns only matching goals

*For any* search pattern, all rows returned by `goal_search` should have `name LIKE '%PATTERN%'`, and no row with a non-matching name should appear.

**Validates: Requirements 9.1**

---

### Property 8: project edit --goal resolves by name

*For any* existing goal name passed to `project edit PROJ_ID --goal GOAL_NAME`, the project's `goal_id` should be updated to the `id` of that goal in the `goals` table.

**Validates: Requirements 11.1**

---

### Property 9: Invalid goal name rejected on project edit

*For any* goal name that does not exist in the `goals` table, `project edit --goal GOAL_NAME` should exit with error and the project's `goal_id` should remain unchanged.

**Validates: Requirements 11.2**

---

## Error Handling

| Situação | Comportamento |
|---|---|
| `GOAL_NAME` ausente em `goal add` | `help_get_message goal_add` |
| `GOAL_ID` ausente em delete/edit/start/stop/complete | `help_get_message goal` |
| `PATTERN` ausente em `goal search` | `help_get_message goal` |
| Area não encontrada (`--area`) | `log_print error "Area '...' not found"` → exit 1 |
| Goal não encontrada (`project edit --goal`) | `log_print error "Goal '...' not found"` → exit 1 |
| ID inválido (não numérico ou inexistente) | `validate_database_id` → `log_print error` → exit 1 |
| Data em formato inválido | `validate_date` → `log_print error` → exit 1 |
| Falha no INSERT/UPDATE/DELETE | `generic_add`/`generic_set_property` → `log_print error` → exit 1 |

Todos os erros usam `log_print error`, que por design chama `exit 1` automaticamente (ver `libs/utils/log.sh`).

---

## Testing Strategy

### Abordagem dual

O projeto usa `tests/unit-tests.sh` com funções de assert definidas em `libs/utils/test.sh`. A estratégia combina:

- **Testes de exemplo**: verificam comportamentos específicos e casos de borda
- **Testes de propriedade**: verificam invariantes universais com múltiplas entradas geradas

### Testes de exemplo (unit tests)

Focados em:
- Fluxo feliz de cada subcomando (`add`, `delete`, `edit`, `list`, `search`, `start`, `stop`, `complete`)
- Casos de borda: nome vazio, ID inexistente, area inexistente, data inválida
- Integração: `project edit --goal GOAL_NAME` resolve corretamente

### Testes de propriedade (property-based)

Para shell scripts, property-based testing é implementado via loops com entradas geradas aleatoriamente dentro do próprio `tests/unit-tests.sh`, sem biblioteca externa. Cada propriedade é executada com mínimo de 100 iterações.

Cada teste de propriedade deve incluir um comentário de rastreabilidade:

```bash
# Feature: goal-crud, Property N: <property_text>
```

**Propriedades a implementar como testes:**

| Property | Implementação |
|---|---|
| P1: Goal add round trip | Loop: gerar nomes aleatórios → inserir → consultar → comparar |
| P2: Area resolution on add | Loop: criar area aleatória → inserir goal → verificar area_id |
| P3: Invalid area rejected | Loop: gerar nomes inexistentes → tentar inserir → verificar tabela inalterada |
| P4: Date validation | Loop: gerar strings inválidas → tentar inserir → verificar sem inserção |
| P5: Status lifecycle | Loop: criar goal → start/stop/complete → verificar status e completed_at |
| P6: Delete removes goal | Loop: inserir → deletar → verificar ausência |
| P7: Search returns matching | Loop: inserir goals com nomes variados → buscar padrão → verificar resultados |
| P8: project edit --goal by name | Loop: criar goal → vincular a project → verificar goal_id |
| P9: Invalid goal rejected on project edit | Loop: nomes inexistentes → tentar vincular → verificar goal_id inalterado |
