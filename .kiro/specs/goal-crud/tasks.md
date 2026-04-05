# Implementation Plan: goal-crud

## Overview

Refatoração completa do módulo Goal (GTD Horizonte 3) no lowbit-planner: criação da tabela `goals` e view `goals_view` no banco, reescrita de `goal.sh` seguindo os padrões atuais do projeto, atualização de `project.sh` para resolver `--goal` por nome, mensagens de ajuda e testes.

## Tasks

- [x] 1. Atualizar schema SQL em `libs/database/database_init.sql`
  - [x] 1.1 Adicionar tabela `goals` e view `goals_view`
    - Inserir bloco `-- Objects:Horizon3:Goal --` após o bloco de `areas`
    - Criar tabela `goals` com campos: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `name TEXT NOT NULL UNIQUE`, `area_id INTEGER`, `vision_id INTEGER`, `status TEXT NOT NULL DEFAULT 'Pending'`, `ranking INTEGER DEFAULT 0`, `start_date TEXT`, `due_date TEXT`, `created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP`, `completed_at TEXT`, `FOREIGN KEY (area_id) REFERENCES areas (id)`
    - Criar view `goals_view` com LEFT JOIN em `areas` expondo: `id`, `name`, `area` (areas.name), `status`, `start_date`, `due_date`, `ranking`
    - _Requirements: 1.1, 1.2, 1.3, 12.6_

  - [x] 1.2 Atualizar view `projects_view` para incluir coluna `goal`
    - Substituir a `CREATE VIEW projects_view` existente por versão com LEFT JOIN em `goals` adicionando `goals.name AS goal`
    - _Requirements: 1.4, 11.3_

- [x] 2. Reescrever `libs/objects/goal.sh`
  - [x] 2.1 Implementar `goal_add()`
    - Arg posicional `GOAL_NAME` obrigatório; sem arg → `help_get_message goal_add`
    - Flag `--area AREA_NAME`: resolver nome → `area_id` via `SELECT id FROM areas WHERE name = '...'`; area não encontrada → `log_print error`
    - Flag `--start-date YYYY-MM-DD`: validar via `validate_date`
    - Flag `--due-date YYYY-MM-DD`: validar via `validate_date`
    - Montar INSERT único e chamar `generic_add "goals" FIELDS VALUES GOAL_NAME`
    - Confirmar via `log_print info` após inserção bem-sucedida
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 12.1, 12.2, 12.3_

  - [ ]* 2.2 Escrever teste de propriedade para `goal_add` round trip (Property 1)
    - **Property 1: Goal add round trip**
    - **Validates: Requirements 2.1, 2.7**

  - [ ]* 2.3 Escrever teste de propriedade para resolução de area em `goal_add` (Property 2)
    - **Property 2: Area resolution on add**
    - **Validates: Requirements 2.2**

  - [ ]* 2.4 Escrever teste de propriedade para rejeição de area inválida (Property 3)
    - **Property 3: Invalid area rejected on add**
    - **Validates: Requirements 2.3, 5.4**

  - [ ]* 2.5 Escrever teste de propriedade para validação de datas (Property 4)
    - **Property 4: Date validation rejects invalid formats**
    - **Validates: Requirements 2.4, 2.5, 5.5, 5.6**

  - [x] 2.6 Implementar `goal_delete()`
    - Arg posicional `GOAL_ID` obrigatório; sem arg → `help_get_message goal`
    - Validar ID via `validate_database_id goals GOAL_ID`
    - Buscar nome para mensagem de confirmação
    - Solicitar confirmação via `log_print user`
    - Executar `DELETE FROM goals WHERE id = GOAL_ID`
    - Confirmar via `log_print info`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 12.2, 12.4_

  - [ ]* 2.7 Escrever teste de propriedade para `goal_delete` (Property 6)
    - **Property 6: Delete removes goal**
    - **Validates: Requirements 4.3**

  - [x] 2.8 Implementar `goal_list()`
    - Chamar `generic_list goals_view`
    - _Requirements: 3.1, 3.2, 12.3_

  - [x] 2.9 Implementar `goal_edit()`
    - Arg posicional `GOAL_ID` obrigatório; sem arg → `help_get_message goal`
    - Validar ID via `validate_database_id goals GOAL_ID`
    - Flag `--name NEW_NAME`: `generic_set_property goals id GOAL_ID name "'NEW_NAME'"`
    - Flag `--area AREA_NAME`: resolver nome → `area_id`; area não encontrada → `log_print error`; `generic_set_property goals id GOAL_ID area_id AREA_ID`
    - Flag `--start-date DATE`: validar via `validate_date`; `generic_set_property`
    - Flag `--due-date DATE`: validar via `validate_date`; `generic_set_property`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 12.2, 12.3, 12.4_

  - [x] 2.10 Implementar `goal_start()`, `goal_stop()`, `goal_complete()`
    - Todos: arg posicional `GOAL_ID` obrigatório; sem arg → `help_get_message goal`
    - Todos: validar ID via `validate_database_id goals GOAL_ID`
    - `goal_start`: `generic_set_property goals id GOAL_ID status "'In Progress'"`
    - `goal_stop`: `generic_set_property goals id GOAL_ID status "'Pending'"`
    - `goal_complete`: setar `status = 'Done'` e `completed_at = DATE('now', 'localtime')` via `generic_set_property`
    - _Requirements: 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 8.1, 8.2, 8.3, 8.4, 12.2, 12.3, 12.4_

  - [ ]* 2.11 Escrever teste de propriedade para ciclo de status (Property 5)
    - **Property 5: Status lifecycle transitions**
    - **Validates: Requirements 6.2, 7.2, 8.2, 8.3**

  - [x] 2.12 Implementar `goal_search()`
    - Arg posicional `PATTERN` obrigatório; sem arg → `help_get_message goal`
    - Executar `database_run box "SELECT * FROM goals_view WHERE name LIKE '%PATTERN%'"`
    - _Requirements: 9.1, 9.2, 12.2_

  - [ ]* 2.13 Escrever teste de propriedade para `goal_search` (Property 7)
    - **Property 7: Search returns only matching goals**
    - **Validates: Requirements 9.1**

  - [x] 2.14 Implementar `goal_main()`
    - Router com cases: `add`, `complete`, `delete`, `edit`, `list`, `search`, `start`, `stop`, `help`, `*`
    - Sem arg → `help_get_message goal`
    - Remover todas as funções camelCase legadas (`goalAdd`, `goalDelete`, `goalHelp`, `goalList`, `goalMain`, `goalRename`)
    - _Requirements: 10.1, 12.1, 12.5_

- [x] 3. Checkpoint — Garantir que goal funciona
  - Garantir que `plan goal add`, `plan goal list`, `plan goal edit`, `plan goal delete`, `plan goal start`, `plan goal stop`, `plan goal complete` e `plan goal search` funcionam. Perguntar ao usuário se houver dúvidas.

- [x] 4. Atualizar `libs/objects/project.sh` para `--goal` por nome
  - [x] 4.1 Atualizar flag `--goal` em `project_edit()` para resolver por nome
    - Substituir `generic_set_property projects id ID goal_id "${1}"` por resolução via `SELECT id FROM goals WHERE name = '${1}'`
    - Goal não encontrada → `log_print error "Goal '...' not found"`
    - `generic_set_property projects id PROJ_ID goal_id GOAL_ID`
    - _Requirements: 11.1, 11.2, 12.2_

  - [ ]* 4.2 Escrever teste de propriedade para `project edit --goal` por nome (Property 8)
    - **Property 8: project edit --goal resolves by name**
    - **Validates: Requirements 11.1**

  - [ ]* 4.3 Escrever teste de propriedade para rejeição de goal inválida em project edit (Property 9)
    - **Property 9: Invalid goal name rejected on project edit**
    - **Validates: Requirements 11.2**

- [x] 5. Adicionar help messages em `libs/utils/help.sh`
  - [x] 5.1 Implementar `help_print_goal()`
    - Seguir padrão de `help_print_project()`: exibir nome, descrição, uso e subcomandos
    - Listar subcomandos: `add`, `complete`, `delete`, `edit`, `list`, `search`, `start`, `stop`
    - _Requirements: 10.1, 10.3_

  - [x] 5.2 Implementar `help_print_goal_add()`
    - Seguir padrão de `help_print_project_add()`: exibir uso, argumentos obrigatórios e opcionais
    - Argumento obrigatório: `GOAL_NAME`
    - Argumentos opcionais: `--area AREA_NAME`, `--start-date YYYY-MM-DD`, `--due-date YYYY-MM-DD`
    - _Requirements: 10.2, 10.4_

  - [x] 5.3 Atualizar `help_print_main()` para incluir `goal`
    - Adicionar linha `goal` na seção OBJECT COMMANDS: `Manage goals (Horizon 3)`
    - _Requirements: 10.1_

- [x] 6. Adicionar testes unitários em `tests/unit-tests.sh`
  - [x] 6.1 Adicionar testes de exemplo para Goal
    - `test_command_output "Goal - help" "./plan.sh goal" "Lowbit Planner - Goal"`
    - `test_command_output "Goal - add" "./plan.sh goal add 'Aprender Rust'" "Item added to goals"`
    - `test_command_output "Goal - list" "./plan.sh goal list" "Aprender Rust"`
    - _Requirements: 10.1, 10.2_

  - [x] 6.2 Adicionar testes de exemplo para `project edit --goal`
    - Criar goal de teste, criar project de teste, executar `plan project edit ID --goal GOAL_NAME`
    - Verificar que `plan project list` exibe o nome da goal na coluna `goal`
    - _Requirements: 11.1, 11.3_

  - [ ]* 6.3 Escrever testes de propriedade para goal no `unit-tests.sh`
    - Implementar Properties 1–9 como loops com entradas geradas, mínimo 5 iterações cada
    - Cada bloco deve incluir comentário `# Feature: goal-crud, Property N: <texto>`
    - _Requirements: 2.1, 2.2, 2.3, 4.3, 6.2, 7.2, 8.2, 9.1, 11.1_

- [x] 7. Checkpoint final — Garantir que todos os testes passam
  - Executar `tests/unit-tests.sh` e garantir saída "All Passed". Perguntar ao usuário se houver dúvidas.

## Notes

- Tasks marcadas com `*` são opcionais e podem ser puladas para MVP mais rápido
- A ordem das tasks reflete dependências reais: schema antes do módulo, módulo antes de project.sh, ambos antes dos testes
- O banco de dados de teste é isolado via `LBPLAN_DB_PATH` em `tests/unit-tests.sh`
- `plan.sh` já faz `source` de `goal.sh` e já tem o case `goal` roteando para `goal_main` — nenhuma alteração necessária em `plan.sh`
- A view `projects_view` precisa ser recriada (DROP + CREATE) pois SQLite não suporta ALTER VIEW
