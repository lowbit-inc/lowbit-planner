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
  state TEXT DEFAULT 'Pending',
  position INTEGER DEFAULT 0,
  FOREIGN KEY (collection_id) REFERENCES collection (id)
);

INSERT INTO collection_item (name, collection_id) VALUES ("Neuromancer",1);
INSERT INTO collection_item (name, collection_id) VALUES ("Persona 5: Royal",2);

CREATE TABLE area (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE
);

INSERT INTO area (name) VALUES ("Personal");
INSERT INTO area (name) VALUES ("Work");

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