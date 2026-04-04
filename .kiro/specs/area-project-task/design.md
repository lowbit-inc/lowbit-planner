# Design Document — area-project-task

## Overview

Este documento descreve o design técnico para a implementação da cadeia GTD **Area → Project → Task** no `lowbit-planner`. A cadeia cobre os horizontes 2 (Area), 1 (Project) e Ground (Task), permitindo que o usuário organize próximas ações em projetos e projetos em áreas de responsabilidade.

A implementação segue os padrões já estabelecidos pelo objeto `inbox`:
- Shell Script puro, sem dependências externas além de `sqlite3`
- Funções genéricas reutilizáveis (`generic_add`, `generic_list`, `generic_set_property`)
- Logging via `log_print` (debug/info/warn/error/user)
- Validação via `validate_database_id`, `validate_date`, `validate_number`
- Help via `help_print_{object}` e `help_print_{object}_add`
- Testes via `test_command_output` em `tests/unit-tests.sh`

Além dos três objetos, este design cobre a correção de quatro bugs identificados no código existente.

---

## Architecture

```
plan.sh (Router)
├── libs/utils/
│   ├── validate.sh     ← bug fix: validate_number
│   ├── system.sh       ← bug fix: system_install
│   └── help.sh         ← novas funções: help_print_area*, help_print_project*
├── libs/database/
│   └── database_init.sql  ← novas tabelas: areas, projects; atualização: tasks
└── libs/objects/
    ├── area.sh         ← reescrita completa (substituir camelCase legado)
    ├── project.sh      ← reescrita completa (substituir camelCase legado)
    └── task.sh         ← completar operações + remover funções legadas
```

Fluxo de uma operação típica:

```
plan area add "Casa" --description "Vida pessoal"
  └─ plan.sh: area_main "$@"
       └─ area_add "Casa" "--description" "Vida pessoal"
            ├─ validate args
            ├─ generic_add "areas" "name, description" "'Casa', 'Vida pessoal'" "Casa"
            │    └─ database_run box "INSERT INTO areas ..."
            └─ log_print info "Item added to areas (Casa)"
```

---

## Components and Interfaces

### 1. `libs/database/database_init.sql`

Responsável pela definição do schema completo. Nenhuma lógica de aplicação aqui.

### 2. `libs/objects/area.sh`

Funções exportadas:
```
area_add()    — adiciona área (name obrigatório, description opcional)
area_delete() — deleta área por ID (com confirmação)
area_edit()   — edita campos via generic_set_property
area_list()   — lista via generic_list areas_view
area_main()   — router interno do objeto
```

### 3. `libs/objects/project.sh`

Funções exportadas:
```
project_add()      — adiciona projeto (name obrigatório, demais opcionais)
project_delete()   — deleta por ID (com confirmação)
project_edit()     — edita campos via generic_set_property
project_list()     — lista via generic_list projects_view
project_start()    — status → 'In Progress'
project_stop()     — status → 'Pending'
project_complete() — status → 'Done' + completed_at = DATE('now')
project_search()   — busca por PATTERN no name (LIKE, case-insensitive)
project_main()     — router interno do objeto
```

### 4. `libs/objects/task.sh`

Funções exportadas (novas/corrigidas):
```
task_add()      — INSERT único com todos os campos opcionais
task_delete()   — deleta por ID (com confirmação)
task_edit()     — edita campos via generic_set_property
task_list()     — lista via generic_list tasks_view
task_start()    — status → 'In Progress'
task_stop()     — status → 'Pending'
task_complete() — status → 'Done' + completed_at = DATE('now')
task_search()   — busca por PATTERN no name (LIKE, case-insensitive)
task_main()     — router interno (já existe, manter)
```

Funções a remover (legado camelCase):
`taskComplete`, `taskDelete`, `taskList`, `taskListCompleted`, `taskRename`,
`taskSetDeadline`, `taskSetProject`, `taskStart`, `taskStop`

### 5. `libs/utils/help.sh`

Novas funções a adicionar:
```
help_print_area()         — help do objeto area
help_print_area_add()     — help do subcomando area add
help_print_project()      — help do objeto project
help_print_project_add()  — help do subcomando project add
```

### 6. `libs/utils/validate.sh` — Bug Fix

```bash
# ANTES (bugado):
function validate_number() {
  this_number="$1"
  if [[ "${this_number}" =~ ^[0-9]+$ ]]; then
    log_print debug "Validation: Value $this_id is a number $this_table"  # ← variáveis erradas
  else
    log_print error "\'$this_id\' is not a number"  # ← variável errada
  fi
}

# DEPOIS (corrigido):
function validate_number() {
  this_number="$1"
  if [[ "${this_number}" =~ ^[0-9]+$ ]]; then
    log_print debug "Validation: Value ${this_number} is a number"
  else
    log_print error "'${this_number}' is not a number"
  fi
}
```

### 7. `libs/utils/system.sh` — Bug Fix

```bash
# ANTES (bugado):
function system_install() {
  log_print user "..."
  ln -s $SCRIPT_DIR/$system_basename /usr/local/bin/plan
}

# DEPOIS (corrigido):
function system_install() {
  log_print user "..."
  if [[ -L /usr/local/bin/plan ]]; then
    log_print warn "Symlink /usr/local/bin/plan already exists — removing before reinstall"
    sudo rm /usr/local/bin/plan
  fi
  sudo ln -s $SCRIPT_DIR/$system_basename /usr/local/bin/plan
  log_print info "Installed as /usr/local/bin/plan"
}
```

### 8. `plan.sh` — Bug Fix

```bash
# ANTES (bugado):
"organize")
  clarify_main   # ← errado

# DEPOIS (corrigido):
"organize")
  organize_main "$@"
```

---

## Data Models

### Schema SQL Completo

#### Tabela `areas`

```sql
CREATE TABLE areas (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW areas_view AS
SELECT id, name, description
FROM areas
ORDER BY id ASC;
```

#### Tabela `projects`

```sql
CREATE TABLE projects (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL UNIQUE,
  area_id      INTEGER,
  goal         TEXT,
  status       TEXT NOT NULL DEFAULT 'Pending',
  ranking      INTEGER DEFAULT 0,
  start_date   TEXT,
  due_date     TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  FOREIGN KEY (area_id) REFERENCES areas (id)
);

CREATE VIEW projects_view AS
SELECT
  projects.id        AS id,
  projects.name      AS name,
  areas.name         AS area,
  projects.status    AS status,
  projects.start_date AS start_date,
  projects.due_date  AS due_date,
  projects.ranking   AS ranking
FROM projects
LEFT JOIN areas ON projects.area_id = areas.id;
```

#### Tabela `tasks` (atualizada)

```sql
CREATE TABLE tasks (
  completed_at TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date     TEXT,
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL UNIQUE,
  project_id   INTEGER,
  start_date   TEXT,
  status       TEXT NOT NULL DEFAULT 'Pending',
  FOREIGN KEY (project_id) REFERENCES projects (id)
);

CREATE VIEW tasks_view AS
SELECT
  tasks.id         AS id,
  tasks.name       AS name,
  projects.name    AS project,
  tasks.start_date AS start_date,
  tasks.due_date   AS due_date,
  tasks.status     AS status
FROM tasks
LEFT JOIN projects ON tasks.project_id = projects.id;
```

### Assinaturas de Funções Detalhadas

#### `area_add()`

```bash
# Uso: area_add NAME [--description DESC]
# Fluxo:
#   1. Verifica arg posicional NAME (obrigatório) → help se ausente
#   2. Parseia --description (opcional)
#   3. Monta INSERT com campos presentes
#   4. Chama generic_add
function area_add() { ... }
```

#### `project_add()`

```bash
# Uso: project_add NAME [--area AREA_ID] [--goal TEXT] [--start-date DATE] [--due-date DATE]
# Fluxo:
#   1. Verifica arg posicional NAME (obrigatório) → help se ausente
#   2. Parseia flags opcionais
#   3. validate_database_id areas AREA_ID (se fornecido)
#   4. validate_date DATE (se fornecido)
#   5. Monta INSERT único com todos os campos
#   6. Chama generic_add
function project_add() { ... }
```

#### `task_add()` (corrigida)

```bash
# Uso: task_add NAME [--project PROJECT_ID] [--start-date DATE] [--due-date DATE]
# Fluxo:
#   1. Verifica arg posicional NAME (obrigatório) → help se ausente
#   2. Parseia flags opcionais
#   3. validate_database_id projects PROJECT_ID (se fornecido)
#   4. validate_date DATE (se fornecido)
#   5. Monta INSERT único com todos os campos (não usa generic_set_property pós-insert)
#   6. Chama generic_add com INSERT completo
function task_add() { ... }
```

#### `{object}_delete()`

```bash
# Uso: {object}_delete ID
# Fluxo:
#   1. Verifica arg ID (obrigatório) → help se ausente
#   2. validate_database_id {table} ID
#   3. Busca name para exibir na confirmação
#   4. log_print user "Confirmar deleção de ID (name)?"
#   5. database_run box "DELETE FROM {table} WHERE id = ID"
#   6. log_print info "Item ID deleted from {table}"
```

#### `{object}_start/stop/complete()`

```bash
# Uso: {object}_start ID
# Fluxo:
#   1. Verifica arg ID → help se ausente
#   2. validate_database_id {table} ID
#   3. generic_set_property {table} id ID status "'In Progress'"
#
# Uso: {object}_stop ID
#   3. generic_set_property {table} id ID status "'Pending'"
#
# Uso: {object}_complete ID
#   3. generic_set_property {table} id ID status "'Done'"
#   4. generic_set_property {table} id ID completed_at "DATE('now', 'localtime')"
```

#### `{object}_search()`

```bash
# Uso: {object}_search PATTERN
# Fluxo:
#   1. Verifica arg PATTERN → help se ausente
#   2. database_run box "SELECT * FROM {table} WHERE name LIKE '%PATTERN%'"
```

#### `{object}_edit()`

```bash
# Uso: {object}_edit ID [--name NEW_NAME] [--description DESC] [--area AREA_ID] ...
# Fluxo:
#   1. Verifica arg ID → help se ausente
#   2. validate_database_id {table} ID
#   3. Para cada flag fornecida: generic_set_property {table} id ID {field} '{value}'
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Area add confirmation

*For any* non-empty area name, executing `plan area add NAME` should produce output containing "Item added to areas".

**Validates: Requirements 4.1**

### Property 2: Area list shows inserted areas

*For any* area inserted via `area add`, executing `plan area list` should return output containing that area's name.

**Validates: Requirements 4.4**

### Property 3: Area edit updates field

*For any* existing area ID and any new value for an editable field (name or description), executing `area edit ID --field VALUE` should result in the field being updated in the database.

**Validates: Requirements 4.7, 4.8**

### Property 4: Area delete removes record

*For any* existing area ID, executing `area delete ID` (confirming) should result in that ID no longer appearing in `area list`.

**Validates: Requirements 4.5**

### Property 5: Project add confirmation with status Pending

*For any* non-empty project name, executing `plan project add NAME` should produce output containing "Item added to projects" and the record should have `status = 'Pending'`.

**Validates: Requirements 5.1**

### Property 6: Project area FK validation

*For any* AREA_ID that does not exist in the `areas` table, executing `plan project add NAME --area AREA_ID` should produce an error message and not insert any record.

**Validates: Requirements 5.2, 5.3**

### Property 7: Date format validation

*For any* string that does not match the pattern `YYYY-MM-DD`, passing it as `--due-date` or `--start-date` to `project add` or `task add` should produce an error and not insert any record.

**Validates: Requirements 5.4, 5.5**

### Property 8: Project start/stop round trip

*For any* project with any initial status, executing `project start ID` followed by `project stop ID` should result in `status = 'Pending'`.

**Validates: Requirements 5.9, 5.10**

### Property 9: Project complete sets status and timestamp

*For any* existing project ID, executing `project complete ID` should result in `status = 'Done'` and `completed_at` being set to a non-null value.

**Validates: Requirements 5.11**

### Property 10: Search returns only matching records

*For any* search pattern, all records returned by `project search PATTERN` or `task search PATTERN` should have a `name` containing that pattern (case-insensitive), and no non-matching records should appear.

**Validates: Requirements 5.13, 6.10**

### Property 11: Task add uses single INSERT with project FK

*For any* combination of optional fields (project_id, start_date, due_date), executing `task add NAME [OPTIONS]` should insert exactly one record with all provided fields set correctly in a single operation.

**Validates: Requirements 6.1**

### Property 12: Task project FK validation

*For any* PROJECT_ID that does not exist in the `projects` table, executing `plan task add NAME --project PROJECT_ID` should produce an error and not insert any record.

**Validates: Requirements 6.2, 6.3**

### Property 13: Task list includes project column

*For any* task linked to a project, executing `plan task list` should show the project name in the output.

**Validates: Requirements 6.4**

### Property 14: Task start/stop round trip

*For any* task with any initial status, executing `task start ID` followed by `task stop ID` should result in `status = 'Pending'`.

**Validates: Requirements 6.6, 6.7**

### Property 15: Task complete sets status and timestamp

*For any* existing task ID, executing `task complete ID` should result in `status = 'Done'` and `completed_at` being set to a non-null value.

**Validates: Requirements 6.8**

### Property 16: validate_number uses correct variable

*For any* non-numeric string passed to `validate_number`, the error message should reference that exact string (not an unrelated variable like `$this_id`).

**Validates: Requirements 9.1**

---

## Error Handling

Todos os erros seguem o padrão existente: `log_print error "mensagem"` que imprime a mensagem e encerra com `exit 1`.

| Situação | Comportamento |
|---|---|
| Argumento obrigatório ausente | `help_get_message {object}_{subcommand}` + `exit 0` |
| ID não encontrado no banco | `log_print error "ID X not found in {table}"` |
| Formato de data inválido | `log_print error "Invalid date format (X) - use YYYY-MM-DD"` |
| Valor não numérico onde número esperado | `log_print error "'X' is not a number"` |
| FK inválida (area_id, project_id) | `log_print error "ID X not found in {table}"` (via validate_database_id) |
| Falha no INSERT/UPDATE/DELETE | `log_print error "Failed to ..."` |

---

## Testing Strategy

### Abordagem Dual

Os testes combinam **testes de exemplo** (casos específicos verificáveis via output) com **testes de propriedade** (comportamento universal verificado via `test_command_output` com dados controlados).

A biblioteca de testes existente (`test_command_output` em `libs/utils/test.sh`) é suficiente para os testes de exemplo. Para propriedades universais, os testes são implementados como loops sobre conjuntos de entradas representativas dentro de `tests/unit-tests.sh`.

### Testes Unitários a Adicionar em `tests/unit-tests.sh`

```bash
# --- Area ---
test_command_output "Area - help"         "./plan.sh area"          "Lowbit Planner - Area"
test_command_output "Area - add"          "./plan.sh area add Casa" "Item added to areas"
test_command_output "Area - list"         "./plan.sh area list"     "Casa"

# --- Project ---
test_command_output "Project - help"      "./plan.sh project"                    "Lowbit Planner - Project"
test_command_output "Project - add"       "./plan.sh project add Arrumar torneira" "Item added to projects"
test_command_output "Project - list"      "./plan.sh project list"               "Arrumar torneira"

# --- Task (com project) ---
# Pré-condição: project ID 1 existe (inserido no teste anterior)
test_command_output "Task - add with project" "./plan.sh task add Comprar peças --project 1" "Item added to tasks"
test_command_output "Task - list shows project column" "./plan.sh task list" "project"

# --- Bug Fixes ---
test_command_output "Organize routes correctly" "./plan.sh organize" "Lowbit Planner"
```

### Configuração de Testes de Propriedade

Cada propriedade identificada na seção anterior deve ser implementada como um único teste de propriedade. Usar mínimo de 100 iterações por propriedade quando aplicável.

Tag format: `# Feature: area-project-task, Property N: {property_text}`

Exemplo:
```bash
# Feature: area-project-task, Property 1: Area add confirmation
for name in "Casa" "Trabalho" "Saúde" "Finanças"; do
  test_command_output "Area add - ${name}" "./plan.sh area add ${name}" "Item added to areas"
done
```

### Ordem de Execução dos Testes

Os testes dependem de estado no banco de dados, portanto devem ser executados em ordem:
1. Testes de sistema (help, version) — sem estado
2. Testes de area (add, list, edit) — cria dados base
3. Testes de project (add com area_id=1, list, start, stop, complete) — depende de area
4. Testes de task (add com project_id=1, list, start, stop, complete) — depende de project
5. Testes de bug fixes (validate_number, organize routing)

O banco de dados de teste deve ser isolado do banco de produção. Verificar se `libs/utils/config.sh` ou `libs/database/database.sh` suportam variável de ambiente para path do banco.
