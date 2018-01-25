SELECT
  teams.id AS id,
  teams.name AS name,
  user_teams.role AS role,
  (
    SELECT COUNT(*)
    FROM user_teams
    WHERE user_teams.team_id = teams.id
  ) AS members,
  CASE WHEN teams.created_by_id = user_teams.user_id THEN false ELSE true END AS can_be_left,
  user_teams.id AS user_team_id,
  user_teams.user_id AS user_id
FROM teams INNER JOIN user_teams ON teams.id=user_teams.team_id
