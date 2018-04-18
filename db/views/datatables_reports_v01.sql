SELECT DISTINCT ON (id)
  reports.id AS id,
  reports.name AS name,
  projects.name AS project_name,
  (
    SELECT users.full_name
    FROM users
    WHERE users.id = reports.user_id
  ) AS created_by,
  (
    SELECT users.full_name
    FROM users
    WHERE users.id = reports.last_modified_by_id
  ) AS last_modified_by,
  reports.created_at AS created_at,
  reports.updated_at AS updated_at,
  projects.archived AS project_archived,
  projects.visibility AS project_visibility,
  projects.id AS project_id,
  reports.team_id AS team_id,
  ARRAY(
    SELECT DISTINCT user_teams.user_id
    FROM user_teams
    WHERE user_teams.team_id = teams.id
  ) AS users_with_team_read_permissions,
  ARRAY(
    SELECT DISTINCT user_projects.user_id
    FROM user_projects
    WHERE user_projects.project_id = projects.id
  ) AS users_with_project_read_permissions
FROM reports
INNER JOIN projects
ON projects.id = reports.project_id
INNER JOIN user_projects
ON user_projects.project_id = projects.id
INNER JOIN teams
ON teams.id = projects.team_id
INNER JOIN user_teams
ON user_teams.team_id = teams.id
