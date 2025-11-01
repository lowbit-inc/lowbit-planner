-- System
CREATE TABLE meta (
  name TEXT UNIQUE,
  value TEXT
);

INSERT INTO meta VALUES ("db_schema", "1");

-- Ground
CREATE TABLE inbox (
  id INTEGER PRIMARY KEY,
  name TEXT
)