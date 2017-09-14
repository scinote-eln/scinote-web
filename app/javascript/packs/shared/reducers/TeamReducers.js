import {
  SET_CURRENT_TEAM,
  GET_LIST_OF_TEAMS,
  SHOW_LEAVE_TEAM_MODAL
} from "../../app/action_types";

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

export const showLeaveTeamModal = (
  state = { show: false, team: { id: 0, name: "", user_team_id: 0 } },
  action
) => {
  if (action.type === SHOW_LEAVE_TEAM_MODAL) {
    return { ...state, ...action.payload };
  }
  return state;
};
