import { SET_CURRENT_USER } from "../../app/action_types";

export function currentUser(
  state = { id: 0, fullName: "", avatarPath: "" },
  action
) {
  if (action.type === SET_CURRENT_USER) {
    return Object.assign({}, state, action.payload);
  }
  return state;
}
