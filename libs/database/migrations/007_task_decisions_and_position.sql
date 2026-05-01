ALTER TABLE tasks ADD COLUMN position INTEGER DEFAULT 0;

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
