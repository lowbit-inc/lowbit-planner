-- System

CREATE TABLE meta (
  name TEXT UNIQUE,
  value TEXT
);

INSERT INTO meta VALUES ("db_schema", "1");

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
SELECT name, description
FROM areas
ORDER BY name ASC;

-- Objects:Horizon4:Vision --

CREATE TABLE visions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL UNIQUE,
  area_id      INTEGER NOT NULL,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'Pending',
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
  visions.status      AS status,
  visions.start_date  AS start_date,
  visions.due_date    AS due_date,
  visions.ranking     AS ranking
FROM visions
LEFT JOIN areas ON visions.area_id = areas.id;

-- Objects:Horizon3:Goal --

CREATE TABLE IF NOT EXISTS goals (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
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

DROP VIEW IF EXISTS goals_view;
CREATE VIEW IF NOT EXISTS goals_view AS
SELECT
  goals.id         AS id,
  goals.name       AS name,
  areas.name       AS area,
  visions.name     AS vision,
  goals.status     AS status,
  goals.start_date AS start_date,
  goals.due_date   AS due_date,
  goals.ranking    AS ranking
FROM goals
LEFT JOIN areas   ON goals.area_id   = areas.id
LEFT JOIN visions ON goals.vision_id = visions.id;

-- Objects:Horizon1:Project --

CREATE TABLE projects (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
  area_id      INTEGER NOT NULL,
  goal_id      INTEGER,
  status       TEXT NOT NULL DEFAULT 'Pending',
  ranking      INTEGER DEFAULT 0,
  start_date   TEXT,
  due_date     TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  FOREIGN KEY (area_id) REFERENCES areas (id)
);

CREATE VIEW IF NOT EXISTS projects_view AS
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

-- Objects:Ground:Task --

CREATE TABLE tasks (
  completed_at TEXT,
  created_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date     TEXT,
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,
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

-------------------------------- Other --------------------------------

-- CREATE TABLE collection (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   name TEXT UNIQUE
-- );

-- INSERT INTO collection (name) VALUES ("Books");
-- INSERT INTO collection (name) VALUES ("Games");

-- CREATE TABLE collection_item (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   name TEXT UNIQUE,
--   collection_id INTEGER NOT NULL,
--   state TEXT DEFAULT "Pending",
--   completion_date TEXT,
--   position INTEGER DEFAULT 0,
--   FOREIGN KEY (collection_id) REFERENCES collection (id)
-- );

-- INSERT INTO collection_item (name, collection_id) VALUES ("Neuromancer",1);
-- INSERT INTO collection_item (name, collection_id) VALUES ("Animal Crossing: New Horizon",2);
-- INSERT INTO collection_item (name, collection_id) VALUES ("Persona 5: Royal",2);
-- INSERT INTO collection_item (name, collection_id) VALUES ("Pokémon Midori",2);

-- CREATE TABLE collection_item_decision (
--   collection_id INTEGER NOT NULL,
--   collection_item_id1 INTEGER NOT NULL,
--   collection_item_id2 INTEGER NOT NULL,
--   collection_item_id_choice INTEGER,
--   FOREIGN KEY (collection_id) REFERENCES collection (id),
--   FOREIGN KEY (collection_item_id1) REFERENCES collection_item (id),
--   FOREIGN KEY (collection_item_id2) REFERENCES collection_item (id),
--   PRIMARY KEY (collection_id, collection_item_id1, collection_item_id2)
-- );

-- CREATE TABLE area (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   name TEXT UNIQUE
-- );

-- INSERT INTO area (name) VALUES ("Personal");
-- INSERT INTO area (name) VALUES ("Work");

---- Idea: try to consolidade the amount of objects for the areas
-- CREATE VIEW area_view AS
-- SELECT area.name AS name, projects, goals, visions
-- FROM area;

-- CREATE TABLE project (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   name TEXT UNIQUE,
--   area_id INTEGER,
--   deadline TEXT,
--   position INTEGER DEFAULT 0,
--   FOREIGN KEY (area_id) REFERENCES area (id)
-- );

-- INSERT INTO project (name, area_id, deadline) VALUES ("Learn lowbit-planner", 1, DATE('now', '+3 days'));
-- INSERT INTO project (name, area_id, deadline) VALUES ("Cool project for my boss", 2, DATE('now', '+7 days'));

-- CREATE VIEW project_view AS
-- SELECT project.id AS id, project.name AS name, area.name AS area, project.deadline AS deadline, project.position AS position
-- FROM project
-- LEFT JOIN area ON project.area_id = area.id;


-- CREATE VIEW task_log AS
-- SELECT task.id AS id, task.name AS name, project.name AS project, task.deadline AS deadline, task.completion_date AS completion_date
-- FROM task
-- LEFT JOIN project ON task.project_id = project.id
-- WHERE state == 'Done' ORDER BY completion_date ASC;

-- CREATE TABLE recurring (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   name TEXT UNIQUE,
--   recurrence TEXT,
--   completion_date TEXT,
--   state TEXT DEFAULT "Pending"
-- );

-- CREATE VIEW recurring_log AS
-- SELECT id, name, recurrence, completion_date, state
-- FROM recurring
-- WHERE state == 'Done';

-- INSERT INTO recurring (name, recurrence) VALUES ("Pay the bills", "monthly");

-- CREATE TABLE habit (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   name TEXT UNIQUE,
--   recurrence TEXT,
--   completion_date TEXT,
--   state TEXT DEFAULT "Pending"
-- );

-- CREATE VIEW habit_log AS
-- SELECT id, name, recurrence, completion_date, state
-- FROM habit
-- WHERE state == 'Done';

-- INSERT INTO habit (name, recurrence) VALUES ("Drink water", "daily");

-- CREATE TABLE goal (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   name TEXT UNIQUE,
--   area_id INTEGER,
--   deadline TEXT,
--   position INTEGER DEFAULT 0,
--   FOREIGN KEY (area_id) REFERENCES area (id)
-- );

-- INSERT INTO goal (name, area_id) VALUES ("Move to new home", 1);

-- CREATE VIEW goal_view AS
-- SELECT goal.id AS id, goal.name AS name, area.name AS area, goal.deadline AS deadline, goal.position AS position
-- FROM goal
-- LEFT JOIN area ON goal.area_id = area.id;

-- CREATE TABLE vision (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   name TEXT UNIQUE,
--   area_id INTEGER,
--   position INTEGER DEFAULT 0,
--   FOREIGN KEY (area_id) REFERENCES area (id)
-- );

-- INSERT INTO vision (name, area_id) VALUES ("Learn Karate", 1);

-- CREATE VIEW vision_view AS
-- SELECT vision.id AS id, vision.name AS name, area.name AS area, vision.position AS position
-- FROM vision
-- LEFT JOIN area ON vision.area_id = area.id;
