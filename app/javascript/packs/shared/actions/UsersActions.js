import axios from "axios";
import { CURRENT_USER_PATH } from "../../app/routes";
import {
  SET_CURRENT_USER,
  CHANGE_CURRENT_USER_FULL_NAME,
  CHANGE_CURRENT_USER_INITIALS,
  CHANGE_CURRENT_USER_EMAIL,
  CHANGE_CURRENT_USER_PASSWORD,
  CHANGE_CURRENT_USER_AVATAR,
  CHANGE_CURRENT_USER_TIMEZONE
} from "../../app/action_types";

function addCurrentUser(data) {
  return {
    type: SET_CURRENT_USER,
    payload: data
  };
}

export function getCurrentUser() {
  return dispatch => {
    axios
      .get(CURRENT_USER_PATH, { withCredentials: true })
      .then(({ data }) => {
        dispatch(addCurrentUser(data.user));
      })
      .catch(error => {
        console.log("get Current User Error: ", error);
      });
  };
}

export function changeFullName(name) {
  return {
    type: CHANGE_CURRENT_USER_FULL_NAME,
    payload: name
  };
}

export function changeInitials(initials) {
  return {
    type: CHANGE_CURRENT_USER_INITIALS,
    payload: initials
  };
}

export function changeEmail(email) {
  return {
    type: CHANGE_CURRENT_USER_EMAIL,
    payload: email
  };
}

export function changePassword(password) {
  return {
    type: CHANGE_CURRENT_USER_PASSWORD,
    payload: password
  };
}

export function changeAvatar(avatarSrc) {
  return {
    type: CHANGE_CURRENT_USER_AVATAR,
    payload: avatarSrc
  };
}

export function changeTimezone(timezone) {
  return {
    type: CHANGE_CURRENT_USER_TIMEZONE,
    payload: timezone
  };
}
