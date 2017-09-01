import { SHOW_LEAVE_TEAM_MODAL } from "../../app/action_types";

export function leaveTeamModalShow(show = false, team = {}) {
  return {
    payload: { team, show },
    type: SHOW_LEAVE_TEAM_MODAL
  };
}
