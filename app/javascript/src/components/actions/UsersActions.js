import { USER_LOGOUT, SET_CURRENT_USER } from "../../config/action_types";

export function destroyState() {
  return { type: USER_LOGOUT };
}

export function addCurrentUser(data) {
  return {
    type: SET_CURRENT_USER,
    payload: data
  };
}
