import { SET_CURRENT_TEAM, GET_LIST_OF_TEAMS } from "../../app/action_types";

const initialState = { name: "", id: 0, current_team: true };
export const setCurrentTeam = (state = initialState, action) => {
  if (action.type === SET_CURRENT_TEAM) {
    return Object.assign({}, state, action.user);
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
