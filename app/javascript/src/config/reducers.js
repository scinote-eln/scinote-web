import { combineReducers } from "redux";
import {
  setCurrentTeam,
  getListOfTeams,
  showLeaveTeamModal,
} from "../components/reducers/TeamReducers";
import { currentUser } from "../components/reducers/UsersReducer";
import { alerts } from "../components/reducers/AlertsReducers";

export default combineReducers({
  current_team: setCurrentTeam,
  all_teams: getListOfTeams,
  current_user: currentUser,
  showLeaveTeamModal,
  alerts
});
