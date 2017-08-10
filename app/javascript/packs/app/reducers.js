import { combineReducers } from "redux";
import {
  setCurrentTeam,
  getListOfTeams
} from "../shared/reducers/TeamReducers";
import { globalActivities } from "../shared/reducers/ActivitiesReducers";
import { currentUser } from "../shared/reducers/UsersReducer";

export default combineReducers({
  current_team: setCurrentTeam,
  all_teams: getListOfTeams,
  global_activities: globalActivities,
  current_user: currentUser
});
