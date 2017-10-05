import { combineReducers } from "redux";
import { USER_LOGOUT } from "./action_types";
import {
  setCurrentTeam,
  getListOfTeams,
  showLeaveTeamModal
} from "../components/reducers/TeamReducers";
import { globalActivities } from "../components/reducers/ActivitiesReducers";
import { currentUser } from "../components/reducers/UsersReducer";
import { alerts } from "../components/reducers/AlertsReducers";

const appReducer = combineReducers({
  current_team: setCurrentTeam,
  all_teams: getListOfTeams,
  global_activities: globalActivities,
  current_user: currentUser,
  showLeaveTeamModal,
  alerts
});

const rootReducer = (state, action) => {
  if (action.type === USER_LOGOUT) {
    state = undefined;
  }
  return appReducer(state, action);
};

export default rootReducer;
