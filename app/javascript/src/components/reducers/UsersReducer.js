import { SET_CURRENT_USER } from "../../config/action_types";

const initialState = {
  id: 0,
  fullName: "",
  initials: "",
  email: "",
  avatarThumb: ""
};

export function currentUser(state = initialState, action) {
  if (action.type === SET_CURRENT_USER) {
    return Object.assign({}, state, action.payload);
  }
  return state;
}
