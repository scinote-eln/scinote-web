// @flow
import type { Teams$Team } from "flow-typed";

export type User = {
  id: number,
  fullName: string,
  initials: string,
  email: string,
  avatarThumb: string
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

export type State = {
  current_team: Teams$Team,
  all_teams: Array<Teams$Team>,
  current_user: User,
  showLeaveTeamModal: boolean,
  alerts: Alert
};
