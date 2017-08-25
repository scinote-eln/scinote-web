import axios from "axios";
import _ from "lodash";
import { TEAMS_PATH, CHANGE_TEAM_PATH } from "../../app/routes";
import { GET_LIST_OF_TEAMS, SET_CURRENT_TEAM } from "../../app/action_types";

function addTeamsData(data) {
  return {
    type: GET_LIST_OF_TEAMS,
    payload: data
  };
}

export function setCurrentUser(user) {
  return {
    user,
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
        dispatch(setCurrentUser(currentTeam));
      })
      .catch(error => {
        console.log("get Teams Error: ", error);
      });
  };
}

export function changeTeam(team_id) {
  return dispatch => {
    axios
      .post(CHANGE_TEAM_PATH, { team_id }, { withCredentials: true })
      .then(response => {
        let teams = _.values(response.data);
        dispatch(addTeamsData(teams));
        let current_team = _.find(teams, team => team.current_team);
        dispatch(setCurrentUser(current_team));
      })
      .catch(error => {
        console.log("get Teams Error: ", error);
      });
  };
}
