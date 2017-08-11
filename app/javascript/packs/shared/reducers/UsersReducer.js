import {
  SET_CURRENT_USER,
  CHANGE_CURRENT_USER_FULL_NAME,
  CHANGE_CURRENT_USER_INITIALS,
  CHANGE_CURRENT_USER_EMAIL
} from "../../app/action_types";

export function currentUser(
  state = {
    id: 0,
    fullName: "",
    initials: "",
    email: "",
    avatarPath: "",
    avatarThumbPath: ""
  },
  action
) {
  switch (action.type) {
    case SET_CURRENT_USER:
      return Object.assign({}, state, action.payload);
    case CHANGE_CURRENT_USER_FULL_NAME:
      return Object.assign({}, state, { fullName: action.payload });
    case CHANGE_CURRENT_USER_INITIALS:
      return Object.assign({}, state, { initials: action.payload });
    case CHANGE_CURRENT_USER_EMAIL:
      return Object.assign({}, state, { email: action.payload });
    default:
      return state;
  }
}
