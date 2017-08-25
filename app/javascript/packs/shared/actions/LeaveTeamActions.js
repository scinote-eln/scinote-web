import { SHOW_LEAVE_TEAM_MODAL } from "../../app/action_types";

export function leaveTeamModalShow(show, id) {
  return({
    payload: { show, id },
    type: SHOW_LEAVE_TEAM_MODAL
  });
}
