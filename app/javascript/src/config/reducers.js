import { combineReducers } from "redux";
import {
  setCurrentTeam,
  getListOfTeams,
  showLeaveTeamModal,
} from "../components/reducers/TeamReducers";
import { globalActivities } from "../components/reducers/ActivitiesReducers";
import { currentUser } from "../components/reducers/UsersReducer";
import { alerts } from "../components/reducers/AlertsReducers";

export default combineReducers({
  current_team: setCurrentTeam,
  all_teams: getListOfTeams,
  global_activities: globalActivities,
  current_user: currentUser,
  showLeaveTeamModal,
  alerts
});
