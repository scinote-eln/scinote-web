import { SHOW_LEAVE_TEAM_MODAL } from "../../app/action_types";

export function showLeaveTeamModal(
  state = { show: false, team: { id: 0, name: "" } },
  action
) {
  if (action.type === SHOW_LEAVE_TEAM_MODAL) {
    return { ...state, ...action.payload };
  }
  return state;
}
