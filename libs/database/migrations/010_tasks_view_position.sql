DROP VIEW IF EXISTS tasks_view;
CREATE VIEW tasks_view AS
SELECT
  tasks.id         AS id,
  tasks.name       AS name,
  projects.name    AS project,
  tasks.start_date AS start_date,
  tasks.due_date   AS due_date,
  tasks.position   AS position,
  tasks.status     AS status
FROM tasks
LEFT JOIN projects ON tasks.project_id = projects.id
ORDER BY
  CASE WHEN tasks.status = 'In Progress' THEN 0 ELSE 1 END ASC,
  CASE WHEN tasks.start_date IS NOT NULL AND tasks.start_date > date('now') THEN 1 ELSE 0 END ASC,
  CASE WHEN tasks.due_date IS NULL THEN 1 ELSE 0 END ASC,
  tasks.due_date ASC,
  tasks.name ASC;
