// @flow
import type { Teams$Team } from "flow-typed";

export type Action$AddTeamData = {
  payload: Array<Teams$Team>,
  type: "GET_LIST_OF_TEAMS"
}

export type Actopm$SetCurrentTeam = {
  team: Teams$Team,
  action: "SET_CURRENT_TEAM"
}
