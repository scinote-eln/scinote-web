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

export type ValidationErrorSimple = {|
  message: string
|};

export type ValidationErrorIntl = {|
  intl: boolean,
  messageId: string,
  values: string
|};

export type ValidationError = ValidationErrorSimple | ValidationErrorIntl;

export type ValidationErrors = string | Array<string> | Array<ValidationError>;

export type Activity = {
  id: number,
  message: string,
  createdAt: string,
  timezone: string,
  project: string,
  task: string
};

export type Notification = {
  id: number,
  title: string,
  message: string,
  typeOf: string,
  createdAt: string,
  avatarThumb: ?string
};

export type State = {
  current_team: Teams$Team,
  all_teams: Array<Teams$Team>,
  current_user: User,
  showLeaveTeamModal: boolean,
  alerts: Alert
};
