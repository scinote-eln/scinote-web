import axios from "../../app/axios";
import _ from "lodash";
import { TEAMS_PATH, CHANGE_TEAM_PATH } from "../../app/routes";
import { GET_LIST_OF_TEAMS, SET_CURRENT_TEAM } from "../../app/action_types";

export function addTeamsData(data) {
  return {
    type: GET_LIST_OF_TEAMS,
    payload: data
  };
}

export function setCurrentTeam(team) {
  return {
    team,
    type: SET_CURRENT_TEAM
  };
}

export function getTeamsList() {
  return dispatch => {
    axios
      .get(TEAMS_PATH, { withCredentials: true })
      .then(response => {
        const teams = response.data.teams.collection;
        dispatch(addTeamsData(teams));
        const currentTeam = _.find(teams, team => team.current_team);
        dispatch(setCurrentTeam(currentTeam));
      })
      .catch(error => {
        console.log("get Teams Error: ", error);
      });
  };
}

export function changeTeam(teamId) {
  return dispatch => {
    axios
      .post(CHANGE_TEAM_PATH, { teamId }, { withCredentials: true })
      .then(response => {
        const teams = response.data.teams.collection;
        dispatch(addTeamsData(teams));
        const currentTeam = _.find(teams, team => team.current_team);
        dispatch(setCurrentTeam(currentTeam));
      })
      .catch(error => {
        console.log("get Teams Error: ", error);
      });
  };
}
