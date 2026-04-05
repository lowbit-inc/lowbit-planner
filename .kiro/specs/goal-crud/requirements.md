# Requirements Document

## Introduction

Implementação do CRUD completo do objeto Goal (Horizonte 3 do GTD) no lowbit-planner.
Goals são metas de 1-2 anos que agrupam Projects (H1) e são opcionalmente vinculadas a uma Area (H2).
O arquivo `libs/objects/goal.sh` existe mas usa convenções antigas (camelCase, tabela `goal` inexistente).
O campo `goal_id` já existe na tabela `projects` aguardando uso.
Esta feature refatora e completa o goal.sh seguindo os padrões atuais do projeto (snake_case, `generic_add`, `generic_list`, `generic_set_property`, `log_print`, `validate_database_id`, `help_print_*`).

## Glossary

- **Goal**: Meta de 1-2 anos (GTD Horizonte 3). Agrupa Projects e pode pertencer a uma Area.
- **Goal_CRUD**: O conjunto de operações add, delete, edit, list, search, start, stop, complete sobre Goals.
- **System**: O CLI `plan.sh` e seus módulos em `libs/`.
- **Goal_Module**: O arquivo `libs/objects/goal.sh`.
- **Database**: O banco SQLite gerenciado por `libs/database/database.sh`.
- **Area**: Área de responsabilidade (GTD Horizonte 2), tabela `areas`.
- **Project**: Projeto (GTD Horizonte 1), tabela `projects`, com coluna `goal_id` nullable.
- **goals_view**: View SQL que expõe Goals com o nome da Area associada.
- **Validator**: Funções `validate_database_id` e `validate_date` em `libs/utils/validate.sh`.
- **Logger**: Função `log_print` em `libs/utils/log.sh`.

---

## Requirements

### Requirement 1: Tabela e View de Goals no banco de dados

**User Story:** Como desenvolvedor, quero que a tabela `goals` e a view `goals_view` existam no banco de dados, para que os dados de Goals possam ser persistidos e consultados.

#### Acceptance Criteria

1. THE Database SHALL conter uma tabela `goals` com as colunas: `id` (INTEGER PRIMARY KEY AUTOINCREMENT), `name` (TEXT NOT NULL UNIQUE), `area_id` (INTEGER, nullable, FOREIGN KEY para `areas.id`), `status` (TEXT NOT NULL DEFAULT 'Pending'), `ranking` (INTEGER DEFAULT 0), `start_date` (TEXT), `due_date` (TEXT), `created_at` (TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP), `completed_at` (TEXT).
2. THE Database SHALL conter uma view `goals_view` que expõe: `id`, `name`, `area` (nome da Area via LEFT JOIN), `status`, `start_date`, `due_date`, `ranking`.
3. WHEN a tabela `goals` for criada, THE Database SHALL aceitar `area_id` como NULL (Goal sem Area associada).
4. THE Database SHALL manter a coluna `goal_id` na tabela `projects` como FOREIGN KEY referenciando `goals.id`.

---

### Requirement 2: Adicionar Goal (goal add)

**User Story:** Como usuário, quero adicionar uma nova Goal, para que eu possa registrar metas de médio prazo no planejador.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal add GOAL_NAME`, THE Goal_Module SHALL inserir um registro na tabela `goals` com o nome fornecido e status padrão `Pending`.
2. WHEN o usuário fornece `--area AREA_NAME`, THE Goal_Module SHALL resolver o nome da Area para `area_id` e incluí-lo no INSERT.
3. IF `--area AREA_NAME` for fornecido e a Area não existir no banco, THEN THE Goal_Module SHALL exibir erro via `log_print error` e encerrar sem inserir.
4. WHEN o usuário fornece `--start-date YYYY-MM-DD`, THE Goal_Module SHALL validar o formato via `validate_date` antes de inserir.
5. WHEN o usuário fornece `--due-date YYYY-MM-DD`, THE Goal_Module SHALL validar o formato via `validate_date` antes de inserir.
6. IF nenhum `GOAL_NAME` for fornecido, THEN THE Goal_Module SHALL exibir a mensagem de ajuda via `help_get_message goal_add`.
7. WHEN a inserção for bem-sucedida, THE Goal_Module SHALL confirmar via `log_print info`.

---

### Requirement 3: Listar Goals (goal list)

**User Story:** Como usuário, quero listar todas as Goals, para que eu possa visualizar minhas metas de médio prazo.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal list`, THE Goal_Module SHALL executar `generic_list goals_view`.
2. THE goals_view SHALL exibir as colunas: `id`, `name`, `area`, `status`, `start_date`, `due_date`, `ranking`.

---

### Requirement 4: Deletar Goal (goal delete)

**User Story:** Como usuário, quero deletar uma Goal pelo ID, para que eu possa remover metas obsoletas.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal delete GOAL_ID`, THE Goal_Module SHALL validar o ID via `validate_database_id goals GOAL_ID`.
2. WHEN o ID for válido, THE Goal_Module SHALL solicitar confirmação via `log_print user` antes de deletar.
3. WHEN confirmado, THE Goal_Module SHALL executar `DELETE FROM goals WHERE id = GOAL_ID`.
4. WHEN a deleção for bem-sucedida, THE Goal_Module SHALL confirmar via `log_print info`.
5. IF nenhum `GOAL_ID` for fornecido, THEN THE Goal_Module SHALL exibir a mensagem de ajuda via `help_get_message goal`.

---

### Requirement 5: Editar Goal (goal edit)

**User Story:** Como usuário, quero editar propriedades de uma Goal existente, para que eu possa atualizar nome, area, datas e outros atributos.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal edit GOAL_ID [FLAGS]`, THE Goal_Module SHALL validar o ID via `validate_database_id goals GOAL_ID`.
2. WHEN o flag `--name NEW_NAME` for fornecido, THE Goal_Module SHALL atualizar o campo `name` via `generic_set_property`.
3. WHEN o flag `--area AREA_NAME` for fornecido, THE Goal_Module SHALL resolver o nome para `area_id` e atualizar via `generic_set_property`.
4. IF `--area AREA_NAME` for fornecido e a Area não existir, THEN THE Goal_Module SHALL exibir erro via `log_print error`.
5. WHEN o flag `--start-date YYYY-MM-DD` for fornecido, THE Goal_Module SHALL validar via `validate_date` e atualizar via `generic_set_property`.
6. WHEN o flag `--due-date YYYY-MM-DD` for fornecido, THE Goal_Module SHALL validar via `validate_date` e atualizar via `generic_set_property`.
7. IF nenhum `GOAL_ID` for fornecido, THEN THE Goal_Module SHALL exibir a mensagem de ajuda via `help_get_message goal`.

---

### Requirement 6: Iniciar Goal (goal start)

**User Story:** Como usuário, quero marcar uma Goal como "In Progress", para que eu possa indicar que estou ativamente trabalhando nela.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal start GOAL_ID`, THE Goal_Module SHALL validar o ID via `validate_database_id goals GOAL_ID`.
2. WHEN o ID for válido, THE Goal_Module SHALL atualizar `status` para `'In Progress'` via `generic_set_property`.
3. IF nenhum `GOAL_ID` for fornecido, THEN THE Goal_Module SHALL exibir a mensagem de ajuda via `help_get_message goal`.

---

### Requirement 7: Pausar Goal (goal stop)

**User Story:** Como usuário, quero marcar uma Goal como "Pending", para que eu possa pausar o trabalho nela.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal stop GOAL_ID`, THE Goal_Module SHALL validar o ID via `validate_database_id goals GOAL_ID`.
2. WHEN o ID for válido, THE Goal_Module SHALL atualizar `status` para `'Pending'` via `generic_set_property`.
3. IF nenhum `GOAL_ID` for fornecido, THEN THE Goal_Module SHALL exibir a mensagem de ajuda via `help_get_message goal`.

---

### Requirement 8: Completar Goal (goal complete)

**User Story:** Como usuário, quero marcar uma Goal como concluída, para que eu possa registrar o alcance da meta.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal complete GOAL_ID`, THE Goal_Module SHALL validar o ID via `validate_database_id goals GOAL_ID`.
2. WHEN o ID for válido, THE Goal_Module SHALL atualizar `status` para `'Done'` via `generic_set_property`.
3. WHEN o ID for válido, THE Goal_Module SHALL atualizar `completed_at` para `DATE('now', 'localtime')` via `generic_set_property`.
4. IF nenhum `GOAL_ID` for fornecido, THEN THE Goal_Module SHALL exibir a mensagem de ajuda via `help_get_message goal`.

---

### Requirement 9: Buscar Goals (goal search)

**User Story:** Como usuário, quero buscar Goals por nome, para que eu possa encontrar metas rapidamente.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal search PATTERN`, THE Goal_Module SHALL executar `SELECT * FROM goals_view WHERE name LIKE '%PATTERN%'`.
2. IF nenhum `PATTERN` for fornecido, THEN THE Goal_Module SHALL exibir a mensagem de ajuda via `help_get_message goal`.

---

### Requirement 10: Mensagens de ajuda (goal help)

**User Story:** Como usuário, quero ver mensagens de ajuda para o comando goal e seus subcomandos, para que eu possa entender como usar a feature.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal help` ou `plan goal` sem subcomando, THE Goal_Module SHALL exibir a ajuda geral via `help_print_goal`.
2. WHEN o usuário executa `plan goal add` sem argumentos, THE Goal_Module SHALL exibir a ajuda específica via `help_print_goal_add`.
3. THE help_print_goal SHALL listar todos os subcomandos: `add`, `complete`, `delete`, `edit`, `list`, `search`, `start`, `stop`.
4. THE help_print_goal_add SHALL listar os argumentos obrigatórios e opcionais do subcomando `add`.

---

### Requirement 11: Vinculação de Projects a Goals

**User Story:** Como usuário, quero vincular um Project a uma Goal via `project edit PROJ_ID --goal GOAL_NAME`, para que eu possa organizar projetos dentro de metas.

#### Acceptance Criteria

1. WHEN o usuário executa `plan project edit PROJ_ID --goal GOAL_NAME`, THE System SHALL resolver o nome da Goal para `goal_id` e atualizar o campo `goal_id` do Project via `generic_set_property`.
2. IF `GOAL_NAME` não existir na tabela `goals`, THEN THE System SHALL exibir erro via `log_print error`.
3. THE projects_view SHALL incluir a coluna `goal` (nome da Goal via LEFT JOIN com `goals`) para exibição.

---

### Requirement 12: Conformidade com padrões do projeto

**User Story:** Como desenvolvedor, quero que o Goal_Module siga os padrões estabelecidos no projeto, para que o código seja consistente e manutenível.

#### Acceptance Criteria

1. THE Goal_Module SHALL usar nomenclatura snake_case para todas as funções (ex: `goal_add`, `goal_main`).
2. THE Goal_Module SHALL usar `log_print debug`, `log_print info`, `log_print error` e `log_print user` para todas as saídas.
3. THE Goal_Module SHALL usar `generic_add`, `generic_list` e `generic_set_property` para operações de banco de dados.
4. THE Goal_Module SHALL usar `validate_database_id` para validar IDs antes de qualquer operação de leitura/escrita por ID.
5. THE Goal_Module SHALL expor uma função `goal_main` que despacha subcomandos via `case` statement.
6. THE database_init.sql SHALL ser atualizado para incluir a tabela `goals` e a view `goals_view` seguindo o padrão dos outros objetos.
