import { combineReducers } from "redux";
import { setCurrentTeam } from "../shared/reducers/TeamReducers";
import { globalActivities } from "../shared/reducers/ActivitiesReducers";

export default combineReducers({
  team: setCurrentTeam,
  global_activities: globalActivities
});
