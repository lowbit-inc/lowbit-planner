DROP VIEW IF EXISTS areas_view;

CREATE VIEW areas_view AS
SELECT
  a.name,
  a.description,
  (SELECT COUNT(*) FROM projects WHERE area_id = a.id AND status != 'Done') AS projects,
  (SELECT COUNT(*) FROM goals    WHERE area_id = a.id AND status != 'Done') AS goals,
  (SELECT COUNT(*) FROM visions  WHERE area_id = a.id AND status != 'Done') AS visions
FROM areas a
ORDER BY a.name ASC;
