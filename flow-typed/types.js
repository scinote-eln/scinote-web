// @flow

export type User = {
  id: number,
  fullName: string,
  initials: string,
  email: string,
  avatarThumb: string
};

export type TeamMember = {
  actions: { current_role: string, team_user_id: number, disable: boolean },
  created_at: string,
  email: string,
  id: number,
  name: string,
  role: string,
  status: string
};

export type NewTeam = {
  name: string,
  description: string
};

export type Alert = {
  message: string,
  type: string,
  id: number,
  timeout: number
};

export type Activity = {
  id: number,
  message: string,
  created_at: string
};

export type Team = {
  id: number,
  name: string,
  current_team: boolean,
  role: string,
  members: number,
  can_be_leaved: boolean
};

export type State = {
  current_team: Team,
  all_teams: Array<Team>,
  current_user: User,
  showLeaveTeamModal: boolean,
  alerts: Alert
};
