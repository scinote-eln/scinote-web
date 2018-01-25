import { combineReducers } from "redux";
import { USER_LOGOUT } from "./action_types";
import {
  setCurrentTeam,
  getListOfTeams
} from "../components/reducers/TeamReducers";
import { currentUser } from "../components/reducers/UsersReducer";
import { alerts } from "../components/reducers/AlertsReducers";

const appReducer = combineReducers({
  current_team: setCurrentTeam,
  all_teams: getListOfTeams,
  current_user: currentUser,
  alerts
});

const rootReducer = (state, action) => {
  if (action.type === USER_LOGOUT) {
    state = undefined;
  }
  return appReducer(state, action);
};

export default rootReducer;
