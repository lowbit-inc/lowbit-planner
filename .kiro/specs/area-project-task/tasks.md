# Implementation Plan: area-project-task

## Overview

Implementação da cadeia GTD Area → Project → Task no lowbit-planner, seguindo a ordem de dependência: bug fixes → schema → area → project → task → help → roteamento → testes.

## Tasks

- [ ] 1. Corrigir bugs existentes
  - [ ] 1.1 Corrigir `validate_number` em `libs/utils/validate.sh`
    - Substituir `$this_id` e `$this_table` por `$this_number` nas mensagens de log da função `validate_number`
    - _Requirements: 9.1_

  - [ ] 1.2 Corrigir `system_install` em `libs/utils/system.sh`
    - Adicionar verificação de symlink existente antes de criar, usando `sudo rm` se necessário e `sudo ln -s`
    - Adicionar `log_print info` de confirmação após instalação
    - _Requirements: 9.2_

  - [ ] 1.3 Corrigir roteamento `organize` em `plan.sh`
    - Alterar `clarify_main` para `organize_main "$@"` no case `organize`
    - _Requirements: 8.3, 9.3_

- [ ] 2. Atualizar schema SQL em `libs/database/database_init.sql`
  - [ ] 2.1 Adicionar tabela `areas` e view `areas_view`
    - Criar tabela com campos: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `name TEXT NOT NULL UNIQUE`, `description TEXT`, `created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP`
    - Criar view `areas_view` selecionando `id`, `name`, `description` ordenado por `id ASC`
    - _Requirements: 1.1, 1.2, 1.3_

  - [ ] 2.2 Adicionar tabela `projects` e view `projects_view`
    - Criar tabela com todos os campos especificados incluindo `FOREIGN KEY (area_id) REFERENCES areas (id)`
    - Criar view `projects_view` com LEFT JOIN em `areas`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ] 2.3 Atualizar tabela `tasks` e view `tasks_view`
    - Adicionar campo `project_id INTEGER` com `FOREIGN KEY (project_id) REFERENCES projects (id)`
    - Atualizar view `tasks_view` para incluir `projects.name AS project` via LEFT JOIN
    - Remover comentários de código legado relacionados a `project_id`
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 3. Implementar `libs/objects/area.sh`
  - [ ] 3.1 Reescrever `area.sh` com funções snake_case
    - Implementar `area_add()`: arg posicional NAME obrigatório, flag `--description` opcional, chamar `generic_add "areas"`
    - Implementar `area_delete()`: validar ID via `validate_database_id`, buscar name para confirmação, `log_print user`, executar DELETE
    - Implementar `area_list()`: chamar `generic_list areas_view`
    - Implementar `area_edit()`: validar ID, parsear flags `--name` e `--description`, chamar `generic_set_property` para cada flag fornecida
    - Implementar `area_main()`: router com cases `add`, `delete`, `edit`, `list`, `help`, `*`
    - Remover todas as funções camelCase legadas (`areaAdd`, `areaDelete`, `areaHelp`, `areaList`, `areaMain`, `areaRename`)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9_

  - [ ]* 3.2 Escrever teste de propriedade para `area_add` (Property 1)
    - **Property 1: Area add confirmation**
    - **Validates: Requirements 4.1**

  - [ ]* 3.3 Escrever teste de propriedade para `area_list` (Property 2)
    - **Property 2: Area list shows inserted areas**
    - **Validates: Requirements 4.4**

  - [ ]* 3.4 Escrever teste de propriedade para `area_edit` (Property 3)
    - **Property 3: Area edit updates field**
    - **Validates: Requirements 4.7, 4.8**

  - [ ]* 3.5 Escrever teste de propriedade para `area_delete` (Property 4)
    - **Property 4: Area delete removes record**
    - **Validates: Requirements 4.5**

- [ ] 4. Checkpoint — Garantir que area funciona
  - Garantir que `plan area add`, `plan area list`, `plan area edit` e `plan area delete` funcionam. Perguntar ao usuário se houver dúvidas.

- [ ] 5. Implementar `libs/objects/project.sh`
  - [ ] 5.1 Reescrever `project.sh` com funções snake_case
    - Implementar `project_add()`: arg posicional NAME obrigatório, flags opcionais `--area`, `--goal`, `--start-date`, `--due-date`; validar `area_id` via `validate_database_id` e datas via `validate_date`; chamar `generic_add "projects"` com INSERT único contendo todos os campos fornecidos
    - Implementar `project_delete()`: validar ID, buscar name, confirmar, executar DELETE
    - Implementar `project_list()`: chamar `generic_list projects_view`
    - Implementar `project_edit()`: validar ID, parsear flags `--name`, `--goal`, `--area`, `--start-date`, `--due-date`, chamar `generic_set_property` para cada flag
    - Implementar `project_start()`: validar ID, `generic_set_property projects id ID status "'In Progress'"`
    - Implementar `project_stop()`: validar ID, `generic_set_property projects id ID status "'Pending'"`
    - Implementar `project_complete()`: validar ID, setar `status = 'Done'` e `completed_at = DATE('now', 'localtime')`
    - Implementar `project_search()`: validar PATTERN, `database_run box "SELECT * FROM projects WHERE name LIKE '%PATTERN%'"`
    - Implementar `project_main()`: router com todos os subcomandos
    - Remover todas as funções camelCase legadas (`projectAdd`, `projectDelete`, `projectHelp`, `projectList`, `projectMain`, `projectRename`)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10, 5.11, 5.12, 5.13, 5.14_

  - [ ]* 5.2 Escrever teste de propriedade para `project_add` status Pending (Property 5)
    - **Property 5: Project add confirmation with status Pending**
    - **Validates: Requirements 5.1**

  - [ ]* 5.3 Escrever teste de propriedade para FK de area em project (Property 6)
    - **Property 6: Project area FK validation**
    - **Validates: Requirements 5.2, 5.3**

  - [ ]* 5.4 Escrever teste de propriedade para validação de datas (Property 7)
    - **Property 7: Date format validation**
    - **Validates: Requirements 5.4, 5.5**

  - [ ]* 5.5 Escrever teste de propriedade para start/stop round trip (Property 8)
    - **Property 8: Project start/stop round trip**
    - **Validates: Requirements 5.9, 5.10**

  - [ ]* 5.6 Escrever teste de propriedade para `project_complete` (Property 9)
    - **Property 9: Project complete sets status and timestamp**
    - **Validates: Requirements 5.11**

  - [ ]* 5.7 Escrever teste de propriedade para `project_search` (Property 10)
    - **Property 10: Search returns only matching records**
    - **Validates: Requirements 5.13**

- [ ] 6. Checkpoint — Garantir que project funciona
  - Garantir que `plan project add`, `plan project list`, `plan project start`, `plan project stop`, `plan project complete` e `plan project search` funcionam. Perguntar ao usuário se houver dúvidas.

- [ ] 7. Completar `libs/objects/task.sh`
  - [ ] 7.1 Reescrever `task_add()` com INSERT único e suporte a `--project`
    - Descomentar e implementar o bloco `--project`: validar `project_id` via `validate_database_id projects`
    - Refatorar para montar INSERT único com todos os campos fornecidos (remover chamadas `generic_set_property` pós-insert)
    - _Requirements: 6.1, 6.2, 6.3_

  - [ ] 7.2 Implementar funções ausentes em `task.sh`
    - Implementar `task_delete()`: validar ID, buscar name, confirmar, executar DELETE
    - Implementar `task_edit()`: validar ID, parsear flags `--name`, `--project`, `--start-date`, `--due-date`, chamar `generic_set_property` para cada flag
    - Implementar `task_start()`: validar ID, `generic_set_property tasks id ID status "'In Progress'"`
    - Implementar `task_stop()`: validar ID, `generic_set_property tasks id ID status "'Pending'"`
    - Implementar `task_complete()`: validar ID, setar `status = 'Done'` e `completed_at = DATE('now', 'localtime')`
    - Implementar `task_search()`: validar PATTERN, `database_run box "SELECT * FROM tasks WHERE name LIKE '%PATTERN%'"`
    - _Requirements: 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10_

  - [ ] 7.3 Remover funções camelCase legadas de `task.sh`
    - Remover: `taskComplete`, `taskDelete`, `taskList`, `taskListCompleted`, `taskRename`, `taskSetDeadline`, `taskSetProject`, `taskStart`, `taskStop`
    - _Requirements: 9.4_

  - [ ]* 7.4 Escrever teste de propriedade para `task_add` com INSERT único (Property 11)
    - **Property 11: Task add uses single INSERT with project FK**
    - **Validates: Requirements 6.1**

  - [ ]* 7.5 Escrever teste de propriedade para FK de project em task (Property 12)
    - **Property 12: Task project FK validation**
    - **Validates: Requirements 6.2, 6.3**

  - [ ]* 7.6 Escrever teste de propriedade para `task_list` com coluna project (Property 13)
    - **Property 13: Task list includes project column**
    - **Validates: Requirements 6.4**

  - [ ]* 7.7 Escrever teste de propriedade para task start/stop round trip (Property 14)
    - **Property 14: Task start/stop round trip**
    - **Validates: Requirements 6.6, 6.7**

  - [ ]* 7.8 Escrever teste de propriedade para `task_complete` (Property 15)
    - **Property 15: Task complete sets status and timestamp**
    - **Validates: Requirements 6.8**

- [ ] 8. Checkpoint — Garantir que task funciona
  - Garantir que `plan task add`, `plan task list`, `plan task start`, `plan task stop`, `plan task complete` e `plan task search` funcionam. Perguntar ao usuário se houver dúvidas.

- [ ] 9. Adicionar help messages em `libs/utils/help.sh`
  - [ ] 9.1 Implementar `help_print_area()` e `help_print_area_add()`
    - `help_print_area`: exibir nome, descrição, uso e subcomandos (`add`, `delete`, `edit`, `list`)
    - `help_print_area_add`: exibir uso, argumento obrigatório `NAME` e flag opcional `--description`
    - _Requirements: 7.1, 7.2, 7.5_

  - [ ] 9.2 Implementar `help_print_project()` e `help_print_project_add()`
    - `help_print_project`: exibir nome, descrição, uso e subcomandos (`add`, `complete`, `delete`, `edit`, `list`, `search`, `start`, `stop`)
    - `help_print_project_add`: exibir uso, argumento obrigatório `NAME` e flags opcionais `--area`, `--goal`, `--start-date`, `--due-date`
    - _Requirements: 7.3, 7.4, 7.5_

- [ ] 10. Adicionar roteamento de `area` e `project` em `plan.sh`
  - Verificar que os cases `area` e `project` chamam `area_main "$@"` e `project_main "$@"` respectivamente (já existem no arquivo, confirmar que estão corretos após reescrita dos objetos)
  - Adicionar `source` de `libs/objects/area.sh` e `libs/objects/project.sh` se não estiverem presentes
  - _Requirements: 8.1, 8.2_

- [ ] 11. Adicionar testes unitários em `tests/unit-tests.sh`
  - [ ] 11.1 Adicionar testes de exemplo para Area
    - `test_command_output "Area - help" "./plan.sh area" "Lowbit Planner - Area"`
    - `test_command_output "Area - add" "./plan.sh area add Casa" "Item added to areas"`
    - `test_command_output "Area - list" "./plan.sh area list" "Casa"`
    - _Requirements: 10.1, 10.2_

  - [ ] 11.2 Adicionar testes de exemplo para Project
    - `test_command_output "Project - help" "./plan.sh project" "Lowbit Planner - Project"`
    - `test_command_output "Project - add" "./plan.sh project add Arrumar torneira" "Item added to projects"`
    - `test_command_output "Project - list" "./plan.sh project list" "Arrumar torneira"`
    - _Requirements: 10.3, 10.4_

  - [ ] 11.3 Adicionar testes de exemplo para Task com project
    - `test_command_output "Task - add with project" "./plan.sh task add Comprar peças --project 1" "Item added to tasks"`
    - `test_command_output "Task - list shows project column" "./plan.sh task list" "project"`
    - _Requirements: 10.5, 10.6_

  - [ ]* 11.4 Escrever teste de propriedade para `validate_number` (Property 16)
    - **Property 16: validate_number uses correct variable**
    - **Validates: Requirements 9.1**

  - [ ] 11.5 Adicionar teste de roteamento do organize
    - `test_command_output "Organize routes correctly" "./plan.sh organize" "Lowbit Planner"`
    - _Requirements: 8.3_

- [ ] 12. Checkpoint final — Garantir que todos os testes passam
  - Executar `tests/unit-tests.sh` e garantir saída "All Passed". Perguntar ao usuário se houver dúvidas.

## Notes

- Tasks marcadas com `*` são opcionais e podem ser puladas para MVP mais rápido
- A ordem das tasks reflete dependências reais: schema antes dos objetos, area antes de project, project antes de task
- Os testes em 11.x dependem de estado no banco — devem ser executados em sequência (area → project → task)
- O banco de dados de teste deve ser isolado do banco de produção; verificar suporte a variável de ambiente em `libs/utils/config.sh` ou `libs/database/database.sh`
- Cada task referencia requisitos específicos para rastreabilidade
