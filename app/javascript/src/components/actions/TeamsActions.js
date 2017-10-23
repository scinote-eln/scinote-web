// @flow
import type {
  Teams$Team,
  Action$LeaveTeam,
  Action$AddTeamData,
  Actopm$SetCurrentTeam
} from "flow-typed";
import type { Dispatch } from "redux-thunk";
import { getTeams, changeCurrentTeam } from "../../services/api/teams_api";
import {
  GET_LIST_OF_TEAMS,
  SET_CURRENT_TEAM
} from "../../config/action_types";

export function addTeamsData(data: Array<Teams$Team>): Action$AddTeamData {
  return {
    type: GET_LIST_OF_TEAMS,
    payload: data
  };
}

export function setCurrentTeam(team: Teams$Team): Actopm$SetCurrentTeam {
  return {
    team,
    type: SET_CURRENT_TEAM
  };
}

export function getTeamsList(): Dispatch {
  return dispatch => {
    getTeams()
      .then(response => {
        const { teams, currentTeam } = response;
        dispatch(addTeamsData(teams));
        dispatch(setCurrentTeam(currentTeam));
      })
      .catch(error => {
        console.log("get Teams Error: ", error);
      });
  };
}

export function changeTeam(teamID: number): Dispatch {
  return dispatch => {
    changeCurrentTeam(teamID)
      .then(response => {
        const { teams, currentTeam } = response;
        dispatch(addTeamsData(teams));
        dispatch(setCurrentTeam(currentTeam));
      })
      .catch(error => {
        console.log("get Teams Error: ", error);
      });
  };
}
