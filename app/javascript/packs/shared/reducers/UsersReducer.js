import {
  SET_CURRENT_USER,
  CHANGE_CURRENT_USER_FULL_NAME,
  CHANGE_CURRENT_USER_INITIALS,
  CHANGE_CURRENT_USER_EMAIL,
  CHANGE_CURRENT_USER_PASSWORD,
  CHANGE_CURRENT_USER_AVATAR
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
    case CHANGE_CURRENT_USER_PASSWORD:
      console.log("handle sending password to the server");
      // return Object.assign({}, state, { password: action.payload });
      return state;
    case CHANGE_CURRENT_USER_AVATAR:
      return Object.assign({}, state, { avatar: action.payload });
    default:
      return state;
  }
}
