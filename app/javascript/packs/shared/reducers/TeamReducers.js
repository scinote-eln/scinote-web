import { SET_CURRENT_TEAM } from '../actions/types';

export const setCurrentTeam = (state = {}, action) => {
  if (action.type === SET_CURRENT_TEAM) {
    return Object.assign({}, state, { currentTeam: action.payload });
  }
  return state;
};
