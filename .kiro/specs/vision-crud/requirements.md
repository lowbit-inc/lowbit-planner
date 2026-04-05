# Requirements Document

## Introduction

Implementação do CRUD completo do objeto Vision (Horizonte 4 do GTD) no lowbit-planner.
Visions são visões de longo prazo (3-5 anos), abstratas, que ficam acima de Goals (H3) na hierarquia GTD e são obrigatoriamente vinculadas a uma Area (H2).
O arquivo `libs/objects/vision.sh` existe mas usa convenções antigas (camelCase, tabela `vision` comentada no SQL, sem uso de `generic_*`, `log_print`, `validate_*`).
O campo `vision_id` já existe na tabela `goals` aguardando uso.
Esta feature refatora e completa o vision.sh seguindo os padrões atuais do projeto (snake_case, `generic_add`, `generic_list`, `generic_set_property`, `log_print`, `validate_database_id`, `help_print_*`), espelhando exatamente os padrões do `goal-crud`.

## Glossary

- **Vision**: Visão de longo prazo (3-5 anos) do GTD Horizonte 4. Pertence obrigatoriamente a uma Area e pode ter Goals vinculadas. Possui ciclo de vida (Pending → In Progress → Done) para representar se o usuário está ativamente trabalhando para que a visão se torne realidade.
- **Vision_CRUD**: O conjunto de operações add, complete, delete, edit, list, search, start, stop sobre Visions.
- **System**: O CLI `plan.sh` e seus módulos em `libs/`.
- **Vision_Module**: O arquivo `libs/objects/vision.sh`.
- **Database**: O banco SQLite gerenciado por `libs/database/database.sh`.
- **Area**: Área de responsabilidade (GTD Horizonte 2), tabela `areas`.
- **Goal**: Meta de 1-2 anos (GTD Horizonte 3), tabela `goals`, com coluna `vision_id` nullable.
- **visions_view**: View SQL que expõe Visions com o nome da Area associada e colunas de status e datas.
- **Validator**: Funções `validate_database_id` e `validate_date` em `libs/utils/validate.sh`.
- **Logger**: Função `log_print` em `libs/utils/log.sh`.

---

## Requirements

### Requirement 1: Tabela e View de Visions no banco de dados

**User Story:** Como desenvolvedor, quero que a tabela `visions` e a view `visions_view` existam no banco de dados, para que os dados de Visions possam ser persistidos e consultados.

#### Acceptance Criteria

1. THE Database SHALL conter uma tabela `visions` com as colunas: `id` (INTEGER PRIMARY KEY AUTOINCREMENT), `name` (TEXT NOT NULL UNIQUE), `area_id` (INTEGER NOT NULL, FOREIGN KEY para `areas.id`), `description` (TEXT), `status` (TEXT NOT NULL DEFAULT 'Pending'), `ranking` (INTEGER DEFAULT 0), `start_date` (TEXT), `due_date` (TEXT), `created_at` (TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP), `completed_at` (TEXT).
2. THE Database SHALL conter uma view `visions_view` que expõe: `id`, `name`, `area` (nome da Area via LEFT JOIN), `description`, `status`, `start_date`, `due_date`, `ranking`.
3. WHEN a tabela `visions` for criada, THE Database SHALL exigir `area_id` como NOT NULL (Vision sem Area não é permitida).
4. THE Database SHALL manter a coluna `vision_id` na tabela `goals` como FOREIGN KEY referenciando `visions.id`.

---

### Requirement 2: Adicionar Vision (vision add)

**User Story:** Como usuário, quero adicionar uma nova Vision, para que eu possa registrar visões de longo prazo no planejador.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision add VISION_NAME --area AREA_NAME`, THE Vision_Module SHALL inserir um registro na tabela `visions` com o nome, `area_id` e status padrão `Pending`.
2. WHEN o usuário fornece `--area AREA_NAME`, THE Vision_Module SHALL resolver o nome da Area para `area_id` e incluí-lo no INSERT.
3. IF `--area AREA_NAME` não for fornecido, THEN THE Vision_Module SHALL exibir a mensagem de ajuda via `help_get_message vision_add`.
4. IF `--area AREA_NAME` for fornecido e a Area não existir no banco, THEN THE Vision_Module SHALL exibir erro via `log_print error` e encerrar sem inserir.
5. WHEN o usuário fornece `--description DESC`, THE Vision_Module SHALL incluir a descrição no INSERT.
6. WHEN o usuário fornece `--start-date YYYY-MM-DD`, THE Vision_Module SHALL validar o formato via `validate_date` antes de inserir.
7. WHEN o usuário fornece `--due-date YYYY-MM-DD`, THE Vision_Module SHALL validar o formato via `validate_date` antes de inserir.
8. IF nenhum `VISION_NAME` for fornecido, THEN THE Vision_Module SHALL exibir a mensagem de ajuda via `help_get_message vision_add`.
9. WHEN a inserção for bem-sucedida, THE Vision_Module SHALL confirmar via `log_print info`.

---

### Requirement 3: Listar Visions (vision list)

**User Story:** Como usuário, quero listar todas as Visions, para que eu possa visualizar minhas visões de longo prazo.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision list`, THE Vision_Module SHALL executar `generic_list visions_view`.
2. THE visions_view SHALL exibir as colunas: `id`, `name`, `area`, `description`, `status`, `start_date`, `due_date`, `ranking`.
3. WHEN o usuário executa `plan vision list`, THE generic_list SHALL filtrar registros com `status != 'Done'` por padrão.

---

### Requirement 4: Deletar Vision (vision delete)

**User Story:** Como usuário, quero deletar uma Vision pelo ID, para que eu possa remover visões obsoletas.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision delete VISION_ID`, THE Vision_Module SHALL validar o ID via `validate_database_id visions VISION_ID`.
2. WHEN o ID for válido, THE Vision_Module SHALL solicitar confirmação via `log_print user` antes de deletar.
3. WHEN confirmado, THE Vision_Module SHALL executar `DELETE FROM visions WHERE id = VISION_ID`.
4. WHEN a deleção for bem-sucedida, THE Vision_Module SHALL confirmar via `log_print info`.
5. IF nenhum `VISION_ID` for fornecido, THEN THE Vision_Module SHALL exibir a mensagem de ajuda via `help_get_message vision`.

---

### Requirement 5: Editar Vision (vision edit)

**User Story:** Como usuário, quero editar propriedades de uma Vision existente, para que eu possa atualizar nome, area e descrição.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision edit VISION_ID [FLAGS]`, THE Vision_Module SHALL validar o ID via `validate_database_id visions VISION_ID`.
2. WHEN o flag `--name NEW_NAME` for fornecido, THE Vision_Module SHALL atualizar o campo `name` via `generic_set_property`.
3. WHEN o flag `--area AREA_NAME` for fornecido, THE Vision_Module SHALL resolver o nome para `area_id` e atualizar via `generic_set_property`.
4. IF `--area AREA_NAME` for fornecido e a Area não existir, THEN THE Vision_Module SHALL exibir erro via `log_print error`.
5. WHEN o flag `--description DESC` for fornecido, THE Vision_Module SHALL atualizar o campo `description` via `generic_set_property`.
6. WHEN o flag `--start-date YYYY-MM-DD` for fornecido, THE Vision_Module SHALL validar via `validate_date` e atualizar via `generic_set_property`.
7. WHEN o flag `--due-date YYYY-MM-DD` for fornecido, THE Vision_Module SHALL validar via `validate_date` e atualizar via `generic_set_property`.
8. IF nenhum `VISION_ID` for fornecido, THEN THE Vision_Module SHALL exibir a mensagem de ajuda via `help_get_message vision_edit`.

---

### Requirement 6: Iniciar Vision (vision start)

**User Story:** Como usuário, quero marcar uma Vision como "In Progress", para que eu possa indicar que estou ativamente trabalhando para que ela se torne realidade.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision start VISION_ID`, THE Vision_Module SHALL validar o ID via `validate_database_id visions VISION_ID`.
2. WHEN o ID for válido, THE Vision_Module SHALL atualizar `status` para `'In Progress'` via `generic_set_property`.
3. IF nenhum `VISION_ID` for fornecido, THEN THE Vision_Module SHALL exibir a mensagem de ajuda via `help_get_message vision`.

---

### Requirement 7: Pausar Vision (vision stop)

**User Story:** Como usuário, quero marcar uma Vision como "Pending", para que eu possa pausar o trabalho nela.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision stop VISION_ID`, THE Vision_Module SHALL validar o ID via `validate_database_id visions VISION_ID`.
2. WHEN o ID for válido, THE Vision_Module SHALL atualizar `status` para `'Pending'` via `generic_set_property`.
3. IF nenhum `VISION_ID` for fornecido, THEN THE Vision_Module SHALL exibir a mensagem de ajuda via `help_get_message vision`.

---

### Requirement 8: Completar Vision (vision complete)

**User Story:** Como usuário, quero marcar uma Vision como concluída, para que eu possa registrar o alcance da visão de longo prazo.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision complete VISION_ID`, THE Vision_Module SHALL validar o ID via `validate_database_id visions VISION_ID`.
2. WHEN o ID for válido, THE Vision_Module SHALL atualizar `status` para `'Done'` via `generic_set_property`.
3. WHEN o ID for válido, THE Vision_Module SHALL atualizar `completed_at` para `DATE('now', 'localtime')` via `generic_set_property`.
4. IF nenhum `VISION_ID` for fornecido, THEN THE Vision_Module SHALL exibir a mensagem de ajuda via `help_get_message vision`.

---

### Requirement 9: Buscar Visions (vision search)

**User Story:** Como usuário, quero buscar Visions por nome, para que eu possa encontrar visões rapidamente.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision search PATTERN`, THE Vision_Module SHALL executar `SELECT * FROM visions_view WHERE name LIKE '%PATTERN%'`.
2. IF nenhum `PATTERN` for fornecido, THEN THE Vision_Module SHALL exibir a mensagem de ajuda via `help_get_message vision`.

---

### Requirement 10: Mensagens de ajuda (vision help)

**User Story:** Como usuário, quero ver mensagens de ajuda para o comando vision e seus subcomandos, para que eu possa entender como usar a feature.

#### Acceptance Criteria

1. WHEN o usuário executa `plan vision help` ou `plan vision` sem subcomando, THE Vision_Module SHALL exibir a ajuda geral via `help_print_vision`.
2. WHEN o usuário executa `plan vision add` sem argumentos, THE Vision_Module SHALL exibir a ajuda específica via `help_print_vision_add`.
3. THE help_print_vision SHALL listar todos os subcomandos: `add`, `complete`, `delete`, `edit`, `list`, `search`, `start`, `stop`.
4. THE help_print_vision_add SHALL listar os argumentos obrigatórios (`VISION_NAME`, `--area`) e opcionais (`--description`, `--start-date`, `--due-date`) do subcomando `add`.

---

### Requirement 11: Vinculação de Goals a Visions

**User Story:** Como usuário, quero vincular uma Goal a uma Vision via `goal add GOAL_NAME --vision VISION_NAME` e `goal edit GOAL_ID --vision VISION_NAME`, para que eu possa organizar metas dentro de visões de longo prazo.

#### Acceptance Criteria

1. WHEN o usuário executa `plan goal add GOAL_NAME --area AREA_NAME --vision VISION_NAME`, THE System SHALL resolver o nome da Vision para `vision_id` e incluí-lo no INSERT da Goal.
2. WHEN o usuário executa `plan goal edit GOAL_ID --vision VISION_NAME`, THE System SHALL resolver o nome da Vision para `vision_id` e atualizar o campo `vision_id` da Goal via `generic_set_property`.
3. IF `VISION_NAME` não existir na tabela `visions`, THEN THE System SHALL exibir erro via `log_print error`.
4. THE goals_view SHALL incluir a coluna `vision` (nome da Vision via LEFT JOIN com `visions`) para exibição.

---

### Requirement 12: Conformidade com padrões do projeto

**User Story:** Como desenvolvedor, quero que o Vision_Module siga os padrões estabelecidos no projeto, para que o código seja consistente e manutenível.

#### Acceptance Criteria

1. THE Vision_Module SHALL usar nomenclatura snake_case para todas as funções (ex: `vision_add`, `vision_main`).
2. THE Vision_Module SHALL usar `log_print debug`, `log_print info`, `log_print error` e `log_print user` para todas as saídas.
3. THE Vision_Module SHALL usar `generic_add`, `generic_list` e `generic_set_property` para operações de banco de dados.
4. THE Vision_Module SHALL usar `validate_database_id` e `validate_date` para validar IDs e datas antes de qualquer operação.
5. THE Vision_Module SHALL expor uma função `vision_main` que despacha subcomandos via `case` statement.
6. THE database_init.sql SHALL ser atualizado para incluir a tabela `visions` e a view `visions_view` seguindo o padrão dos outros objetos.
