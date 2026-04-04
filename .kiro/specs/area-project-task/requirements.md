# Requirements Document

## Introduction

Este documento especifica os requisitos para a implementação da cadeia completa de objetos GTD no lowbit-planner: **Area → Project → Task**. A cadeia representa os horizontes 2, 1 e Ground do GTD, respectivamente, onde Area agrupa Projects e Projects agrupam Tasks (next actions).

A implementação segue a filosofia "lowbit": Shell Script puro com SQLite, sem dependências externas, reutilizando os padrões já estabelecidos pelos objetos `inbox` e `task` (parcial).

Além dos três objetos principais, este spec também cobre a correção de bugs identificados no código existente que impactam diretamente a cadeia implementada.

---

## Glossary

- **System**: O CLI `lowbit-planner` invocado via `plan.sh`
- **Area**: Objeto GTD de Horizonte 2 — esfera de responsabilidade ou interesse do usuário
- **Project**: Objeto GTD de Horizonte 1 — resultado com múltiplos passos, vinculado a uma Area
- **Task**: Objeto GTD de Ground — próxima ação concreta, opcionalmente vinculada a um Project
- **Database**: Banco de dados SQLite gerenciado por `libs/database/database.sh`
- **Schema**: Arquivo `libs/database/database_init.sql` que define tabelas e views
- **Generic_Module**: Funções reutilizáveis em `libs/objects/generic.sh` (`generic_add`, `generic_list`, `generic_set_property`)
- **Validator**: Funções de validação em `libs/utils/validate.sh`
- **Logger**: Função `log_print` em `libs/utils/log.sh`
- **Help_Module**: Funções de help em `libs/utils/help.sh`
- **Router**: O `case` statement em `plan.sh` que roteia comandos para objetos
- **Status**: Estado de ciclo de vida de um objeto — valores válidos: `Pending`, `In Progress`, `Done`
- **FK**: Foreign Key — chave estrangeira no banco de dados SQLite
- **ID**: Identificador inteiro único gerado automaticamente pelo banco (AUTOINCREMENT)
- **Area Name Identifier**: Para o objeto Area, o `name` é usado como identificador na interface CLI (em vez do `id`), pois áreas são estáveis e poucas. O `id` existe internamente apenas para FKs.

---

## Requirements

### Requirement 1: Schema do Banco de Dados — Area

**User Story:** Como desenvolvedor, quero que a tabela `areas` e sua view existam no schema do banco, para que o objeto Area possa persistir dados.

#### Acceptance Criteria

1. THE Schema SHALL definir a tabela `areas` com os campos: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `name TEXT NOT NULL UNIQUE`, `description TEXT`, `created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP`
2. THE Schema SHALL definir a view `areas_view` que seleciona apenas `name` e `description` da tabela `areas` (sem `id`), ordenada por `name ASC`
3. WHEN o banco de dados é inicializado, THE Database SHALL criar a tabela `areas` e a view `areas_view` sem erros

---

### Requirement 2: Schema do Banco de Dados — Project

**User Story:** Como desenvolvedor, quero que a tabela `projects` e sua view existam no schema do banco, para que o objeto Project possa persistir dados com FK para Area.

#### Acceptance Criteria

1. THE Schema SHALL definir a tabela `projects` com os campos: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `name TEXT NOT NULL UNIQUE`, `area_id INTEGER NOT NULL`, `goal_id INTEGER`, `status TEXT NOT NULL DEFAULT 'Pending'`, `ranking INTEGER DEFAULT 0`, `start_date TEXT`, `due_date TEXT`, `created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP`, `completed_at TEXT`
2. THE Schema SHALL definir `FOREIGN KEY (area_id) REFERENCES areas (id)` na tabela `projects`
3. THE Schema SHALL definir a view `projects_view` que seleciona `projects.id`, `projects.name`, `areas.name AS area`, `projects.status`, `projects.start_date`, `projects.due_date`, `projects.ranking` via LEFT JOIN com `areas`
4. WHEN o banco de dados é inicializado, THE Database SHALL criar a tabela `projects` e a view `projects_view` sem erros

---

### Requirement 3: Schema do Banco de Dados — Task (atualização)

**User Story:** Como desenvolvedor, quero que a tabela `tasks` inclua o campo `project_id` com FK para `projects`, para que Tasks possam ser vinculadas a Projects.

#### Acceptance Criteria

1. THE Schema SHALL adicionar o campo `project_id INTEGER` à tabela `tasks`
2. THE Schema SHALL definir `FOREIGN KEY (project_id) REFERENCES projects (id)` na tabela `tasks`
3. THE Schema SHALL atualizar a view `tasks_view` para incluir `projects.name AS project` via LEFT JOIN com `projects`
4. WHEN o banco de dados é inicializado, THE Database SHALL criar a tabela `tasks` atualizada sem erros

---

### Requirement 4: Objeto Area — Operações CRUD

**User Story:** Como usuário, quero gerenciar áreas de responsabilidade via CLI, para que eu possa organizar meus projetos por contexto de vida.

#### Acceptance Criteria

1. WHEN o usuário executa `plan area add NAME`, THE System SHALL inserir um registro na tabela `areas` com o `name` fornecido e exibir mensagem de confirmação via `log_print info`
2. WHEN o usuário executa `plan area add NAME --description DESC`, THE System SHALL inserir o registro com o campo `description` preenchido
3. WHEN o usuário executa `plan area add` sem argumentos, THE System SHALL exibir a mensagem de help `area_add` e encerrar com código 0
4. WHEN o usuário executa `plan area list`, THE System SHALL exibir todos os registros da view `areas_view` em formato tabular
5. WHEN o usuário executa `plan area delete NAME`, THE System SHALL solicitar confirmação via `log_print user`, deletar o registro correspondente e exibir confirmação
6. WHEN o usuário executa `plan area delete NAME` com um nome inexistente, THE Validator SHALL emitir erro via `log_print error` e encerrar
7. WHEN o usuário executa `plan area edit NAME --name NEW_NAME`, THE System SHALL atualizar o campo `name` do registro via `generic_set_property`
8. WHEN o usuário executa `plan area edit NAME --description NEW_DESC`, THE System SHALL atualizar o campo `description` do registro via `generic_set_property`
9. WHEN o usuário executa `plan area` sem subcomando, THE System SHALL exibir a mensagem de help `area` e encerrar com código 0

---

### Requirement 5: Objeto Project — Operações CRUD e Ciclo de Vida

**User Story:** Como usuário, quero gerenciar projetos vinculados a áreas via CLI, para que eu possa organizar minhas próximas ações em resultados concretos.

#### Acceptance Criteria

1. WHEN o usuário executa `plan project add NAME`, THE System SHALL inserir um registro na tabela `projects` com `name` e `status = 'Pending'` e exibir confirmação
2. WHEN o usuário executa `plan project add NAME --area AREA_NAME`, THE Validator SHALL verificar que `AREA_NAME` existe na tabela `areas` (por nome) antes de inserir
3. IF o `AREA_NAME` fornecido não existir na tabela `areas`, THEN THE Validator SHALL emitir erro via `log_print error` e encerrar
4. IF o usuário executa `plan project add NAME` sem `--area`, THEN THE System SHALL emitir erro via `log_print error` informando que área é obrigatória
4. WHEN o usuário executa `plan project add NAME --due-date DATE`, THE Validator SHALL verificar que `DATE` está no formato `YYYY-MM-DD` antes de inserir
5. WHEN o usuário executa `plan project add NAME --start-date DATE`, THE Validator SHALL verificar que `DATE` está no formato `YYYY-MM-DD` antes de inserir
6. WHEN o usuário executa `plan project add NAME --area AREA_NAME`, THE System SHALL inserir o registro sem campo `goal_id` (vínculo com Goal será implementado futuramente via spec de Horizonte 3)
7. WHEN o usuário executa `plan project list`, THE System SHALL exibir todos os registros da view `projects_view` em formato tabular
8. WHEN o usuário executa `plan project delete ID`, THE System SHALL solicitar confirmação, deletar o registro e exibir confirmação
9. WHEN o usuário executa `plan project start ID`, THE System SHALL atualizar `status` para `'In Progress'` via `generic_set_property`
10. WHEN o usuário executa `plan project stop ID`, THE System SHALL atualizar `status` para `'Pending'` via `generic_set_property`
11. WHEN o usuário executa `plan project complete ID`, THE System SHALL atualizar `status` para `'Done'` e `completed_at` para a data atual via `generic_set_property`
12. WHEN o usuário executa `plan project edit ID --name NEW_NAME`, THE System SHALL atualizar o campo `name` via `generic_set_property`
13. WHEN o usuário executa `plan project search PATTERN`, THE System SHALL exibir registros da tabela `projects` cujo `name` contenha `PATTERN` (case-insensitive)
14. WHEN o usuário executa `plan project` sem subcomando, THE System SHALL exibir a mensagem de help `project` e encerrar com código 0

---

### Requirement 6: Objeto Task — Operações Completas e Vinculação a Project

**User Story:** Como usuário, quero gerenciar tarefas (próximas ações) com suporte a vinculação a projetos via CLI, para que eu possa executar meu trabalho de forma organizada.

#### Acceptance Criteria

1. WHEN o usuário executa `plan task add NAME`, THE System SHALL inserir um registro na tabela `tasks` com todos os campos em um único `INSERT` (incluindo `due_date`, `start_date`, `project_id` quando fornecidos)
2. WHEN o usuário executa `plan task add NAME --project PROJECT_ID`, THE Validator SHALL verificar que `PROJECT_ID` existe na tabela `projects` antes de inserir
3. IF o `PROJECT_ID` fornecido não existir na tabela `projects`, THEN THE Validator SHALL emitir erro via `log_print error` e encerrar
4. WHEN o usuário executa `plan task list`, THE System SHALL exibir todos os registros da view `tasks_view` (incluindo coluna `project`) em formato tabular
5. WHEN o usuário executa `plan task delete ID`, THE System SHALL solicitar confirmação, deletar o registro e exibir confirmação
6. WHEN o usuário executa `plan task start ID`, THE System SHALL atualizar `status` para `'In Progress'` via `generic_set_property`
7. WHEN o usuário executa `plan task stop ID`, THE System SHALL atualizar `status` para `'Pending'` via `generic_set_property`
8. WHEN o usuário executa `plan task complete ID`, THE System SHALL atualizar `status` para `'Done'` e `completed_at` para a data atual via `generic_set_property`
9. WHEN o usuário executa `plan task edit ID --name NEW_NAME`, THE System SHALL atualizar o campo `name` via `generic_set_property`
10. WHEN o usuário executa `plan task search PATTERN`, THE System SHALL exibir registros da tabela `tasks` cujo `name` contenha `PATTERN` (case-insensitive)

---

### Requirement 7: Help Messages — Area e Project

**User Story:** Como usuário, quero mensagens de help claras para os comandos `area` e `project`, para que eu possa descobrir os subcomandos disponíveis sem consultar documentação externa.

#### Acceptance Criteria

1. THE Help_Module SHALL implementar a função `help_print_area` que exibe nome, descrição, uso e lista de subcomandos do objeto `area`
2. THE Help_Module SHALL implementar a função `help_print_area_add` que exibe uso, argumentos obrigatórios e opcionais do subcomando `area add`
3. THE Help_Module SHALL implementar a função `help_print_project` que exibe nome, descrição, uso e lista de subcomandos do objeto `project`
4. THE Help_Module SHALL implementar a função `help_print_project_add` que exibe uso, argumentos obrigatórios e opcionais do subcomando `project add`
5. WHEN `help_get_message` é chamada com argumento `area`, `area_add`, `project` ou `project_add`, THE Help_Module SHALL exibir a mensagem correspondente e encerrar com código 0

---

### Requirement 8: Roteamento em plan.sh

**User Story:** Como usuário, quero que os comandos `area`, `project` e `organize` sejam roteados corretamente pelo CLI, para que os subcomandos funcionem como esperado.

#### Acceptance Criteria

1. WHEN o usuário executa `plan area SUBCOMMAND`, THE Router SHALL chamar `area_main "$@"` com os argumentos restantes
2. WHEN o usuário executa `plan project SUBCOMMAND`, THE Router SHALL chamar `project_main "$@"` com os argumentos restantes
3. WHEN o usuário executa `plan organize`, THE Router SHALL chamar `organize_main` (e não `clarify_main`)

---

### Requirement 9: Correção de Bugs Existentes

**User Story:** Como desenvolvedor, quero que os bugs identificados no código existente sejam corrigidos, para que o sistema funcione de forma confiável como base para os novos objetos.

#### Acceptance Criteria

1. THE Validator SHALL corrigir a função `validate_number` para usar a variável `$this_number` nas mensagens de log (em vez de `$this_id` e `$this_table`)
2. THE System SHALL corrigir `system_install` para verificar se o symlink já existe antes de tentar criá-lo, evitando falha silenciosa em reinstalações
3. THE Router SHALL corrigir o case `organize` em `plan.sh` para chamar `organize_main` em vez de `clarify_main`
4. THE System SHALL remover as funções legadas em camelCase de `task.sh` (`taskComplete`, `taskDelete`, `taskList`, `taskListCompleted`, `taskRename`, `taskSetDeadline`, `taskSetProject`, `taskStart`, `taskStop`)

---

### Requirement 10: Testes Unitários

**User Story:** Como desenvolvedor, quero testes unitários para os novos objetos e correções, para que eu possa verificar o comportamento esperado de forma automatizada.

#### Acceptance Criteria

1. THE Test_Suite SHALL incluir um teste para `plan area add NAME` que verifica a mensagem de confirmação "Item added to areas"
2. THE Test_Suite SHALL incluir um teste para `plan area list` que verifica que o comando executa sem erro
3. THE Test_Suite SHALL incluir um teste para `plan project add NAME` que verifica a mensagem de confirmação "Item added to projects"
4. THE Test_Suite SHALL incluir um teste para `plan project list` que verifica que o comando executa sem erro
5. THE Test_Suite SHALL incluir um teste para `plan task add NAME --project PROJECT_ID` que verifica a mensagem de confirmação "Item added to tasks"
6. THE Test_Suite SHALL incluir um teste para `plan task list` que verifica que a coluna `project` aparece na saída
7. WHEN todos os testes são executados via `tests/unit-tests.sh`, THE Test_Suite SHALL encerrar com a mensagem "All Passed"

