import { SHOW_LEAVE_TEAM_MODAL } from "../../app/action_types";

export function leaveTeamModalShow(show, id, teamName) {
  return({
    payload: { show, id, teamName },
    type: SHOW_LEAVE_TEAM_MODAL
  });
}
