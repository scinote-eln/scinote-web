import {
  SET_CURRENT_TEAM,
  GET_LIST_OF_TEAMS
} from "../../config/action_types";

export const setCurrentTeam = (
  state = { name: "", id: 0, current_team: true },
  action
) => {
  if (action.type === SET_CURRENT_TEAM) {
    return Object.assign({}, state, action.team);
  }
  return state;
};

export const getListOfTeams = (state = { collection: [] }, action) => {
  if (action.type === GET_LIST_OF_TEAMS) {
    return {
      ...state,
      collection: action.payload
    };
  }
  return state;
};
