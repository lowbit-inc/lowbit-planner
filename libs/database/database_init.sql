-- System

CREATE TABLE meta (
  name TEXT UNIQUE,
  value TEXT
);

INSERT INTO meta VALUES ("db_schema", "7");

-- Workflow:Reflect:Reviews --

CREATE TABLE reviews (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  horizon          TEXT NOT NULL UNIQUE,
  last_reviewed_at TEXT
);

INSERT INTO reviews (horizon) VALUES ('ground');
INSERT INTO reviews (horizon) VALUES ('horizon1');
INSERT INTO reviews (horizon) VALUES ('horizon2');
INSERT INTO reviews (horizon) VALUES ('horizon3');
INSERT INTO reviews (horizon) VALUES ('horizon4');
INSERT INTO reviews (horizon) VALUES ('horizon5');

-- Objects:Ground:Inbox --

CREATE TABLE inbox (
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE VIEW inbox_view AS
SELECT inbox.id AS id, inbox.name AS name
FROM inbox
ORDER BY id ASC;

-- Objects:Horizon2:Area --

CREATE TABLE areas (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW areas_view AS
SELECT
  a.name,
  a.description,
  (SELECT COUNT(*) FROM projects WHERE area_id = a.id AND status != 'Done') AS projects,
  (SELECT COUNT(*) FROM goals    WHERE area_id = a.id AND status != 'Done') AS goals,
  (SELECT COUNT(*) FROM visions  WHERE area_id = a.id AND status != 'Done') AS visions
FROM areas a
ORDER BY a.name ASC;

-- Objects:Horizon4:Vision --

CREATE TABLE visions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL UNIQUE,
  area_id      INTEGER NOT NULL,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'Pending',
  position     INTEGER DEFAULT 0,
  ranking      INTEGER DEFAULT 0,
  start_date   TEXT,
  due_date     TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  FOREIGN KEY (area_id) REFERENCES areas (id)
);

CREATE VIEW visions_view AS
SELECT
  visions.id          AS id,
  visions.name        AS name,
  areas.name          AS area,
  visions.description AS description,
  visions.start_date  AS start_date,
  visions.due_date    AS due_date,
  visions.position    AS position,
  visions.status      AS status
FROM visions
LEFT JOIN areas ON visions.area_id = areas.id
ORDER BY CASE WHEN visions.status = 'In Progress' THEN 0 WHEN visions.status = 'Pending' THEN 1 ELSE 2 END, visions.position DESC, visions.name ASC;

-- Objects:Horizon3:Goal --

CREATE TABLE IF NOT EXISTS goals (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  area_id      INTEGER,
  vision_id    INTEGER,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'Pending',
  position     INTEGER DEFAULT 0,
  ranking      INTEGER DEFAULT 0,
  start_date   TEXT,
  due_date     TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  FOREIGN KEY (area_id) REFERENCES areas (id)
);

DROP VIEW IF EXISTS goals_view;
CREATE VIEW IF NOT EXISTS goals_view AS
SELECT
  goals.id          AS id,
  goals.name        AS name,
  areas.name        AS area,
  visions.name      AS vision,
  goals.description AS description,
  goals.start_date  AS start_date,
  goals.due_date   AS due_date,
  goals.position   AS position,
  goals.status     AS status
FROM goals
LEFT JOIN areas   ON goals.area_id   = areas.id
LEFT JOIN visions ON goals.vision_id = visions.id
ORDER BY CASE WHEN goals.status = 'In Progress' THEN 0 WHEN goals.status = 'Pending' THEN 1 ELSE 2 END, goals.position DESC, goals.name ASC;

-- Objects:Horizon1:Project --

CREATE TABLE projects (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  area_id      INTEGER NOT NULL,
  goal_id      INTEGER,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'Pending',
  position     INTEGER DEFAULT 0,
  ranking      INTEGER DEFAULT 0,
  start_date   TEXT,
  due_date     TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  FOREIGN KEY (area_id) REFERENCES areas (id)
);

CREATE VIEW IF NOT EXISTS projects_view AS
SELECT
  projects.id          AS id,
  projects.name        AS name,
  areas.name           AS area,
  goals.name           AS goal,
  projects.description AS description,
  projects.start_date  AS start_date,
  projects.due_date   AS due_date,
  projects.position   AS position,
  projects.status     AS status
FROM projects
LEFT JOIN areas ON projects.area_id = areas.id
LEFT JOIN goals ON projects.goal_id = goals.id
ORDER BY CASE WHEN projects.status = 'In Progress' THEN 0 WHEN projects.status = 'Pending' THEN 1 ELSE 2 END, projects.position DESC, projects.name ASC;

-- Objects:Ground:Task --

CREATE TABLE tasks (
  completed_at TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date     TEXT,
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  position     INTEGER DEFAULT 0,
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
LEFT JOIN projects ON tasks.project_id = projects.id
ORDER BY
  CASE WHEN tasks.status = 'In Progress' THEN 0 ELSE 1 END ASC,
  CASE WHEN tasks.start_date IS NOT NULL AND tasks.start_date > date('now') THEN 1 ELSE 0 END ASC,
  CASE WHEN tasks.due_date IS NULL THEN 1 ELSE 0 END ASC,
  tasks.due_date ASC,
  tasks.name ASC;

-- Objects:Horizon5:Purpose --

CREATE TABLE purposes (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW purposes_view AS
SELECT id, name, description
FROM purposes
ORDER BY name ASC;

-- Objects:Horizon5:Principle --

CREATE TABLE principles (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW principles_view AS
SELECT id, name, description
FROM principles
ORDER BY name ASC;

-- Objects:Ground:Recurring --

CREATE TABLE recurrings (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL UNIQUE,
  recurrence   TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'Pending',
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT
);

CREATE VIEW recurrings_view AS
SELECT id, name, recurrence, status
FROM recurrings
ORDER BY CASE WHEN status = 'In Progress' THEN 0 WHEN status = 'Pending' THEN 1 ELSE 2 END, name ASC;

-- Objects:Ground:Habit --

CREATE TABLE habits (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL UNIQUE,
  recurrence   TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'Pending',
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT
);

CREATE VIEW habits_view AS
SELECT id, name, recurrence, status
FROM habits
ORDER BY CASE WHEN status = 'In Progress' THEN 0 WHEN status = 'Pending' THEN 1 ELSE 2 END, name ASC;

-- Objects:Ground:Collection --

CREATE TABLE collections (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW collections_view AS
SELECT id, name
FROM collections
ORDER BY name ASC;

-- Objects:Ground:Collection Item --

CREATE TABLE collection_items (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  collection_id INTEGER NOT NULL,
  status        TEXT NOT NULL DEFAULT 'Pending',
  position      INTEGER DEFAULT 0,
  ranking       INTEGER DEFAULT 0,
  created_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at  TEXT,
  FOREIGN KEY (collection_id) REFERENCES collections (id)
);

CREATE VIEW collection_items_view AS
SELECT
  collection_items.id     AS id,
  collection_items.name   AS name,
  collections.name        AS collection,
  collection_items.position AS position,
  collection_items.ranking  AS ranking,
  collection_items.status AS status
FROM collection_items
LEFT JOIN collections ON collection_items.collection_id = collections.id
ORDER BY CASE WHEN collection_items.status = 'In Progress' THEN 0 WHEN collection_items.status = 'Pending' THEN 1 ELSE 2 END, collection_items.position DESC, collection_items.name ASC;

-- Workflow:Decision:Collection Item Decisions --

CREATE TABLE collection_item_decisions (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  collection_id INTEGER NOT NULL,
  item_id_low   INTEGER NOT NULL,
  item_id_high  INTEGER NOT NULL,
  choice_id     INTEGER,
  created_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at    TEXT,
  FOREIGN KEY (collection_id) REFERENCES collections (id),
  FOREIGN KEY (item_id_low)   REFERENCES collection_items (id),
  FOREIGN KEY (item_id_high)  REFERENCES collection_items (id),
  FOREIGN KEY (choice_id)     REFERENCES collection_items (id),
  CHECK (item_id_low < item_id_high),
  UNIQUE (collection_id, item_id_low, item_id_high)
);

-- Workflow:Decision:Vision Decisions --

CREATE TABLE vision_decisions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id_low  INTEGER NOT NULL,
  item_id_high INTEGER NOT NULL,
  choice_id    INTEGER,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at   TEXT,
  FOREIGN KEY (item_id_low)  REFERENCES visions (id),
  FOREIGN KEY (item_id_high) REFERENCES visions (id),
  FOREIGN KEY (choice_id)    REFERENCES visions (id),
  CHECK (item_id_low < item_id_high),
  UNIQUE (item_id_low, item_id_high)
);

-- Workflow:Decision:Goal Decisions --

CREATE TABLE goal_decisions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id_low  INTEGER NOT NULL,
  item_id_high INTEGER NOT NULL,
  choice_id    INTEGER,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at   TEXT,
  FOREIGN KEY (item_id_low)  REFERENCES goals (id),
  FOREIGN KEY (item_id_high) REFERENCES goals (id),
  FOREIGN KEY (choice_id)    REFERENCES goals (id),
  CHECK (item_id_low < item_id_high),
  UNIQUE (item_id_low, item_id_high)
);

-- Workflow:Decision:Project Decisions --

CREATE TABLE project_decisions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id_low  INTEGER NOT NULL,
  item_id_high INTEGER NOT NULL,
  choice_id    INTEGER,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at   TEXT,
  FOREIGN KEY (item_id_low)  REFERENCES projects (id),
  FOREIGN KEY (item_id_high) REFERENCES projects (id),
  FOREIGN KEY (choice_id)    REFERENCES projects (id),
  CHECK (item_id_low < item_id_high),
  UNIQUE (item_id_low, item_id_high)
);

-- Workflow:Decision:Task Decisions --

CREATE TABLE task_decisions (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id    INTEGER NOT NULL,
  item_id_low   INTEGER NOT NULL,
  item_id_high  INTEGER NOT NULL,
  choice_id     INTEGER,
  created_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at    TEXT,
  FOREIGN KEY (project_id)   REFERENCES projects (id),
  FOREIGN KEY (item_id_low)  REFERENCES tasks (id),
  FOREIGN KEY (item_id_high) REFERENCES tasks (id),
  FOREIGN KEY (choice_id)    REFERENCES tasks (id),
  CHECK (item_id_low < item_id_high),
  UNIQUE (project_id, item_id_low, item_id_high)
);
