import { combineReducers } from "redux";
import {
  setCurrentTeam,
  getListOfTeams,
  showLeaveTeamModal,
} from "../components/reducers/TeamReducers";
import { globalActivities } from "../components/reducers/ActivitiesReducers";
import { currentUser } from "../components/reducers/UsersReducer";

export default combineReducers({
  current_team: setCurrentTeam,
  all_teams: getListOfTeams,
  global_activities: globalActivities,
  current_user: currentUser,
  showLeaveTeamModal
});
