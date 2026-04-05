# Implementation Plan: vision-crud

## Overview

Refatoração completa do módulo Vision (GTD Horizonte 4) no lowbit-planner: criação da tabela `visions` e view `visions_view` no banco, atualização da `goals_view` para incluir coluna `vision`, reescrita de `vision.sh` seguindo os padrões atuais do projeto, atualização de `goal.sh` para resolver `--vision` por nome, mensagens de ajuda e testes.

## Tasks

- [x] 1. Atualizar schema SQL em `libs/database/database_init.sql`
  - [x] 1.1 Adicionar tabela `visions` e view `visions_view`
    - Inserir bloco `-- Objects:Horizon4:Vision --` após o bloco de `areas` e antes do bloco de `goals`
    - Criar tabela `visions` com campos: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `name TEXT NOT NULL UNIQUE`, `area_id INTEGER NOT NULL`, `description TEXT`, `status TEXT NOT NULL DEFAULT 'Pending'`, `ranking INTEGER DEFAULT 0`, `start_date TEXT`, `due_date TEXT`, `created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP`, `completed_at TEXT`, `FOREIGN KEY (area_id) REFERENCES areas (id)`
    - Criar view `visions_view` com LEFT JOIN em `areas` expondo: `id`, `name`, `area` (areas.name), `description`, `status`, `start_date`, `due_date`, `ranking`
    - _Requirements: 1.1, 1.2, 1.3, 12.6_

  - [x] 1.2 Atualizar view `goals_view` para incluir coluna `vision`
    - Substituir a `CREATE VIEW IF NOT EXISTS goals_view` existente por versão com LEFT JOIN em `visions` adicionando `visions.name AS vision`
    - A view deve expor: `id`, `name`, `area` (areas.name), `vision` (visions.name), `status`, `start_date`, `due_date`, `ranking`
    - SQLite não suporta ALTER VIEW — usar DROP + CREATE
    - _Requirements: 1.4, 11.4_

- [x] 2. Reescrever `libs/objects/vision.sh`
  - [x] 2.1 Implementar `vision_add()`
    - Arg posicional `VISION_NAME` obrigatório; sem arg → `help_get_message vision_add`
    - Flag `--area AREA_NAME` obrigatória: resolver nome → `area_id` via `SELECT id FROM areas WHERE name = '...'`; area não encontrada → `log_print error`; `--area` ausente → `help_get_message vision_add`
    - Flag `--description DESC`: opcional, incluído no INSERT se fornecido
    - Flag `--start-date YYYY-MM-DD`: validar via `validate_date`
    - Flag `--due-date YYYY-MM-DD`: validar via `validate_date`
    - Montar INSERT único e chamar `generic_add "visions" FIELDS VALUES VISION_NAME`
    - Confirmar via `log_print info` após inserção bem-sucedida
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 12.1, 12.2, 12.3_

  - [ ]* 2.2 Escrever teste de propriedade para `vision_add` round trip (Property 1)
    - **Property 1: Vision add round trip**
    - **Validates: Requirements 2.1, 2.2**

  - [ ]* 2.3 Escrever teste de propriedade para resolução de area em `vision_add` (Property 2)
    - **Property 2: Area resolution stores correct area_id**
    - **Validates: Requirements 2.2, 5.3**

  - [ ]* 2.4 Escrever teste de propriedade para rejeição de area inválida (Property 3)
    - **Property 3: Invalid area rejected**
    - **Validates: Requirements 2.4, 5.4**

  - [ ]* 2.5 Escrever teste de propriedade para validação de datas (Property 4)
    - **Property 4: Date validation rejects invalid formats**
    - **Validates: Requirements 2.6, 2.7, 5.6, 5.7**

  - [ ]* 2.6 Escrever teste de propriedade para rejeição de vision sem area_id (Property 5)
    - **Property 5: Vision without area_id rejected by database**
    - **Validates: Requirements 1.3**

  - [x] 2.7 Implementar `vision_delete()`
    - Arg posicional `VISION_ID` obrigatório; sem arg → `help_get_message vision`
    - Validar ID via `validate_database_id visions VISION_ID`
    - Buscar nome para mensagem de confirmação
    - Solicitar confirmação e executar deleção via `generic_delete`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 12.2, 12.4_

  - [ ]* 2.8 Escrever teste de propriedade para `vision_delete` (Property 7)
    - **Property 7: Delete removes vision**
    - **Validates: Requirements 4.3**

  - [x] 2.9 Implementar `vision_list()`
    - Chamar `generic_list visions_view "status != 'Done'"`
    - _Requirements: 3.1, 3.2, 3.3, 12.3_

  - [ ]* 2.10 Escrever teste de propriedade para `vision_list` excluindo concluídas (Property 8)
    - **Property 8: List excludes completed visions**
    - **Validates: Requirements 3.3**

  - [x] 2.11 Implementar `vision_edit()`
    - Arg posicional `VISION_ID` obrigatório; sem arg → `help_get_message vision_edit`
    - Validar ID via `validate_database_id visions VISION_ID`
    - Flag `--name NEW_NAME`: `generic_set_property visions id VISION_ID name "'NEW_NAME'"`
    - Flag `--area AREA_NAME`: resolver nome → `area_id`; area não encontrada → `log_print error`; `generic_set_property visions id VISION_ID area_id AREA_ID`
    - Flag `--description DESC`: `generic_set_property visions id VISION_ID description "'DESC'"`
    - Flag `--start-date DATE`: validar via `validate_date`; `generic_set_property`
    - Flag `--due-date DATE`: validar via `validate_date`; `generic_set_property`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 12.2, 12.3, 12.4_

  - [x] 2.12 Implementar `vision_start()`, `vision_stop()`, `vision_complete()`
    - Todos: arg posicional `VISION_ID` obrigatório; sem arg → `help_get_message vision`
    - Todos: validar ID via `validate_database_id visions VISION_ID`
    - `vision_start`: `generic_set_status "visions" VISION_ID "In Progress"`
    - `vision_stop`: `generic_set_status "visions" VISION_ID "Pending"`
    - `vision_complete`: `generic_complete "visions" VISION_ID`
    - _Requirements: 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 8.1, 8.2, 8.3, 8.4, 12.2, 12.3, 12.4_

  - [ ]* 2.13 Escrever teste de propriedade para ciclo de status (Property 6)
    - **Property 6: Status lifecycle transitions**
    - **Validates: Requirements 6.2, 7.2, 8.2, 8.3**

  - [x] 2.14 Implementar `vision_search()`
    - Arg posicional `PATTERN` obrigatório; sem arg → `help_get_message vision`
    - Executar `database_run box "SELECT * FROM visions_view WHERE name LIKE '%PATTERN%'"`
    - _Requirements: 9.1, 9.2, 12.2_

  - [ ]* 2.15 Escrever teste de propriedade para `vision_search` (Property 9)
    - **Property 9: Search returns only matching visions**
    - **Validates: Requirements 9.1**

  - [x] 2.16 Implementar `vision_main()`
    - Router com cases: `add`, `complete`, `delete`, `edit`, `list`, `search`, `start`, `stop`, `help`, `*`
    - Sem arg → `help_get_message vision`
    - Remover todas as funções camelCase legadas (`visionAdd`, `visionDelete`, `visionHelp`, `visionList`, `visionMain`, `visionRename`)
    - _Requirements: 10.1, 12.1, 12.5_

- [x] 3. Checkpoint — Garantir que vision funciona
  - Garantir que `plan vision add`, `plan vision list`, `plan vision edit`, `plan vision delete`, `plan vision start`, `plan vision stop`, `plan vision complete` e `plan vision search` funcionam. Perguntar ao usuário se houver dúvidas.

- [x] 4. Atualizar `libs/objects/goal.sh` para `--vision` por nome
  - [x] 4.1 Atualizar flag `--vision` em `goal_add()` para resolver por nome
    - Adicionar case `--vision` no loop de flags de `goal_add`
    - Resolver nome via `SELECT id FROM visions WHERE name = '${1}'`
    - Vision não encontrada → `log_print error "Vision '...' not found"`
    - Incluir `vision_id` nos campos e valores do INSERT
    - _Requirements: 11.1, 11.3, 12.2_

  - [x] 4.2 Atualizar flag `--vision` em `goal_edit()` para resolver por nome
    - Adicionar case `--vision` no loop de flags de `goal_edit`
    - Resolver nome via `SELECT id FROM visions WHERE name = '${1}'`
    - Vision não encontrada → `log_print error "Vision '...' not found"`
    - `generic_set_property goals id GOAL_ID vision_id VISION_ID`
    - _Requirements: 11.2, 11.3, 12.2_

  - [ ]* 4.3 Escrever teste de propriedade para `goal add/edit --vision` por nome (Property 10)
    - **Property 10: Vision name resolution in goal operations**
    - **Validates: Requirements 11.1, 11.2**

  - [ ]* 4.4 Escrever teste de propriedade para rejeição de vision inválida em goal (Property 11)
    - **Property 11: Invalid vision name rejected in goal operations**
    - **Validates: Requirements 11.3**

- [x] 5. Adicionar help messages em `libs/utils/help.sh`
  - [x] 5.1 Implementar `help_print_vision()`
    - Seguir padrão de `help_print_goal()`: exibir nome, descrição, uso e subcomandos
    - Listar subcomandos: `add`, `complete`, `delete`, `edit`, `list`, `search`, `start`, `stop`
    - _Requirements: 10.1, 10.3_

  - [x] 5.2 Implementar `help_print_vision_add()`
    - Seguir padrão de `help_print_goal_add()`: exibir uso, argumentos obrigatórios e opcionais
    - Argumentos obrigatórios: `VISION_NAME`, `--area AREA_NAME`
    - Argumentos opcionais: `--description DESC`, `--start-date YYYY-MM-DD`, `--due-date YYYY-MM-DD`
    - _Requirements: 10.2, 10.4_

  - [x] 5.3 Implementar `help_print_vision_edit()`
    - Seguir padrão de `help_print_goal_edit()`: exibir uso, argumento obrigatório e opcionais
    - Argumento obrigatório: `VISION_ID`
    - Argumentos opcionais: `--name`, `--area`, `--description`, `--start-date`, `--due-date`
    - _Requirements: 10.2_

  - [x] 5.4 Atualizar `help_print_main()` para incluir `vision`
    - Adicionar linha `vision` na seção OBJECT COMMANDS: `Manage visions (Horizon 4)`
    - Inserir após a linha de `goal` para manter ordem hierárquica
    - _Requirements: 10.1_

- [x] 6. Adicionar testes unitários em `tests/unit-tests.sh`
  - [x] 6.1 Adicionar testes de exemplo para Vision
    - `test_command_output "Vision - help" "./plan.sh vision" "Lowbit Planner - Vision"`
    - `test_command_output "Vision - add" "./plan.sh vision add 'Ser fluente em japonês' --area Casa" "Item added to visions"`
    - `test_command_output "Vision - list" "./plan.sh vision list" "Ser fluente em japonês"`
    - _Requirements: 10.1, 10.2_

  - [x] 6.2 Adicionar testes de exemplo para `goal add/edit --vision` por nome
    - Criar vision de teste, criar goal de teste com `--vision VISION_NAME`
    - Verificar que `plan goal list` exibe o nome da vision na coluna `vision`
    - Executar `plan goal edit ID --vision VISION_NAME` e verificar atualização
    - _Requirements: 11.1, 11.2, 11.4_

  - [ ]* 6.3 Escrever testes de propriedade para vision no `unit-tests.sh`
    - Implementar Properties 1–11 como loops com entradas geradas, mínimo 5 iterações cada
    - Cada bloco deve incluir comentário `# Feature: vision-crud, Property N: <texto>`
    - _Requirements: 2.1, 2.2, 2.4, 1.3, 4.3, 3.3, 6.2, 7.2, 8.2, 9.1, 11.1, 11.2_

- [x] 7. Checkpoint final — Garantir que todos os testes passam
  - Executar `tests/unit-tests.sh` e garantir saída "All Passed". Perguntar ao usuário se houver dúvidas.

## Notes

- Tasks marcadas com `*` são opcionais e podem ser puladas para MVP mais rápido
- A ordem das tasks reflete dependências reais: schema antes do módulo, módulo antes de goal.sh, ambos antes dos testes
- O banco de dados de teste é isolado via `LBPLAN_DB_PATH` em `tests/unit-tests.sh`
- `plan.sh` já faz `source` de `vision.sh` e já tem o case `vision` roteando para `vision_main` — nenhuma alteração necessária em `plan.sh`
- A view `goals_view` precisa ser recriada (DROP + CREATE) pois SQLite não suporta ALTER VIEW
- `area_id` em `visions` é NOT NULL (diferença em relação a `goals`) — Vision sem Area não é permitida
- A coluna `vision_id` já existe na tabela `goals` aguardando uso — nenhuma alteração de schema na tabela `goals` é necessária
