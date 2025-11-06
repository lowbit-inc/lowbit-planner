-- System
CREATE TABLE meta (
  name TEXT UNIQUE,
  value TEXT
);

INSERT INTO meta VALUES ("db_schema", "1");

-- Objects
CREATE TABLE inbox (
  id INTEGER PRIMARY KEY,
  name TEXT
);

INSERT INTO inbox (name) VALUES ("Some idea I had");

CREATE TABLE collection (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE
);

INSERT INTO collection (name) VALUES ("Books");
INSERT INTO collection (name) VALUES ("Games");

CREATE TABLE collection_item (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  collection_id INTEGER NOT NULL,
  state TEXT DEFAULT "Pending",
  completion_date TEXT,
  position INTEGER DEFAULT 0,
  FOREIGN KEY (collection_id) REFERENCES collection (id)
);

INSERT INTO collection_item (name, collection_id) VALUES ("Neuromancer",1);
INSERT INTO collection_item (name, collection_id) VALUES ("Animal Crossing: New Horizon",2);
INSERT INTO collection_item (name, collection_id) VALUES ("Persona 5: Royal",2);
INSERT INTO collection_item (name, collection_id) VALUES ("Pokémon Midori",2);

CREATE TABLE collection_item_decision (
  collection_id INTEGER NOT NULL,
  collection_item_id1 INTEGER NOT NULL,
  collection_item_id2 INTEGER NOT NULL,
  collection_item_id_choice INTEGER,
  FOREIGN KEY (collection_id) REFERENCES collection (id),
  FOREIGN KEY (collection_item_id1) REFERENCES collection_item (id),
  FOREIGN KEY (collection_item_id2) REFERENCES collection_item (id),
  PRIMARY KEY (collection_id, collection_item_id1, collection_item_id2)
);

CREATE TABLE area (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE
);

INSERT INTO area (name) VALUES ("Personal");
INSERT INTO area (name) VALUES ("Work");

---- Idea: try to consolidade the amount of objects for the areas
-- CREATE VIEW area_view AS
-- SELECT area.name AS name, projects, goals, visions
-- FROM area;

CREATE TABLE project (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  area_id INTEGER,
  deadline TEXT,
  position INTEGER DEFAULT 0,
  FOREIGN KEY (area_id) REFERENCES area (id)
);

INSERT INTO project (name, area_id, deadline) VALUES ("Learn lowbit-planner", 1, DATE('now', '+3 days'));
INSERT INTO project (name, area_id, deadline) VALUES ("Cool project for my boss", 2, DATE('now', '+7 days'));

CREATE VIEW project_view AS
SELECT project.id AS id, project.name AS name, area.name AS area, project.deadline AS deadline, project.position AS position
FROM project
LEFT JOIN area ON project.area_id = area.id;

CREATE TABLE task (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  project_id INTEGER,
  deadline TEXT,
  completion_date TEXT,
  state TEXT DEFAULT "Pending",
  FOREIGN KEY (project_id) REFERENCES project (id)
);

INSERT INTO task (name, project_id, deadline) VALUES ("Complete this task", 1, DATE('now', '+1 day'));
INSERT INTO task (name) VALUES ("Procrastinate");

CREATE VIEW task_view AS
SELECT task.id AS id, task.name AS name, project.name AS project, task.deadline AS deadline, task.state AS state
FROM task
LEFT JOIN project ON task.project_id = project.id
WHERE state <> 'Done' ORDER BY deadline ASC NULLS LAST, state DESC;

CREATE VIEW task_log AS
SELECT task.id AS id, task.name AS name, project.name AS project, task.deadline AS deadline, task.completion_date AS completion_date
FROM task
LEFT JOIN project ON task.project_id = project.id
WHERE state == 'Done' ORDER BY completion_date ASC;

CREATE TABLE recurring (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  recurrence TEXT,
  completion_date TEXT,
  state TEXT DEFAULT "Pending"
);

CREATE VIEW recurring_log AS
SELECT id, name, recurrence, completion_date, state
FROM recurring
WHERE state == 'Done';

INSERT INTO recurring (name, recurrence) VALUES ("Pay the bills", "monthly");

CREATE TABLE habit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  recurrence TEXT,
  completion_date TEXT,
  state TEXT DEFAULT "Pending"
);

CREATE VIEW habit_log AS
SELECT id, name, recurrence, completion_date, state
FROM habit
WHERE state == 'Done';

INSERT INTO habit (name, recurrence) VALUES ("Drink water", "daily");

CREATE TABLE goal (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  area_id INTEGER,
  deadline TEXT,
  position INTEGER DEFAULT 0,
  FOREIGN KEY (area_id) REFERENCES area (id)
);

INSERT INTO goal (name, area_id) VALUES ("Move to new home", 1);

CREATE VIEW goal_view AS
SELECT goal.id AS id, goal.name AS name, area.name AS area, goal.deadline AS deadline, goal.position AS position
FROM goal
LEFT JOIN area ON goal.area_id = area.id;

CREATE TABLE vision (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  area_id INTEGER,
  position INTEGER DEFAULT 0,
  FOREIGN KEY (area_id) REFERENCES area (id)
);

INSERT INTO vision (name, area_id) VALUES ("Learn Karate", 1);

CREATE VIEW vision_view AS
SELECT vision.id AS id, vision.name AS name, area.name AS area, vision.position AS position
FROM vision
LEFT JOIN area ON vision.area_id = area.id;
