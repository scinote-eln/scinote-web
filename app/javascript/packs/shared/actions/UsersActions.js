import axios from "../../app/axios";

import {
  CHANGE_USER_FULL_NAME_PATH,
  CURRENT_USER_PATH,
  CHANGE_USER_INITIALS_PATH
} from "../../app/routes";

import {
  SET_CURRENT_USER,
  CHANGE_CURRENT_USER_FULL_NAME,
  CHANGE_CURRENT_USER_INITIALS,
  CHANGE_CURRENT_USER_EMAIL,
  CHANGE_CURRENT_USER_PASSWORD,
  CHANGE_CURRENT_USER_AVATAR,
  CHANGE_CURRENT_USER_TIMEZONE,
  CHANGE_ASSIGNMENTS_NOTIFICATION,
  CHANGE_ASSIGNMENTS_NOTIFICATION_EMAIL,
  CHANGE_RECENT_NOTIFICATION,
  CHANGE_RECENT_NOTIFICATION_EMAIL,
  CHANGE_SYSTEM_MESSAGE_NOTIFICATION_EMAIL
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

export function savedChangedFullName({ fullName }) {
  return {
    type: CHANGE_CURRENT_USER_FULL_NAME,
    payload: fullName
  };
}

export function changeFullName(name) {
  return dispatch => {
    axios
      .post(CHANGE_USER_FULL_NAME_PATH, {
        withCredentials: true,
        fullName: name
      })
      .then(({ data }) => {
        dispatch(savedChangedFullName(data));
      })
      .catch(err => console.log(err));
  };
}

export function savedChangeInitials({ initials }) {
  return {
    type: CHANGE_CURRENT_USER_INITIALS,
    payload: initials
  };
}

export function changeInitials(initials) {
  return dispatch => {
    axios
      .post(CHANGE_USER_INITIALS_PATH, {
        withCredentials: true,
        initials
      })
      .then(({ data }) => {
        dispatch(savedChangeInitials(data));
      })
      .catch(err => console.log(err));
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

export function changeAssignmentsNotification(status) {
  return {
    type: CHANGE_ASSIGNMENTS_NOTIFICATION,
    payload: status
  };
}

export function changeAssignmentsNotificationEmail(status) {
  return {
    type: CHANGE_ASSIGNMENTS_NOTIFICATION_EMAIL,
    payload: status
  };
}

export function changeRecentNotification(status) {
  return {
    type: CHANGE_RECENT_NOTIFICATION,
    payload: status
  };
}

export function changeRecentNotificationEmail(status) {
  return {
    type: CHANGE_RECENT_NOTIFICATION_EMAIL,
    payload: status
  };
}

export function changeSystemMessageNotificationEmail(status) {
  return {
    type: CHANGE_SYSTEM_MESSAGE_NOTIFICATION_EMAIL,
    payload: status
  };
}
