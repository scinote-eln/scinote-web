import axios from "../../app/axios";

import {
  CHANGE_USER_FULL_NAME_PATH,
  CURRENT_USER_PATH,
  CHANGE_USER_INITIALS_PATH,
  CHANGE_USER_EMAIL_PATH,
  CHANGE_USER_PASSWORD_PATH,
  CHANGE_USER_TIMEZONE_PATH,
  CHANGE_USER_ASSIGNEMENTS_NOTIFICATION_PATH,
  CHANGE_USER_ASSIGNMENTS_NOTIFICATION_EMAIL_PATH,
  CHANGE_USER_RECENT_NOTIFICATION_PATH,
  CHANGE_USER_RECENT_NOTIFICATION_EMAIL_PATH,
  CHANGE_USER_SYSTEM_MESSAGE_NOTIFICATION_EMAIL_PATH
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

export function saveFullName({ fullName }) {
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
        dispatch(saveFullName(data));
      })
      .catch(err => console.log(err));
  };
}

export function saveInitials({ initials }) {
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
        dispatch(saveInitials(data));
      })
      .catch(err => console.log(err));
  };
}

export function saveEmail({ email }) {
  return {
    type: CHANGE_CURRENT_USER_EMAIL,
    payload: email
  };
}

export function changeEmail(email) {
  return dispatch => {
    axios
      .post(CHANGE_USER_EMAIL_PATH, {
        withCredentials: true,
        email
      })
      .then(({ data }) => {
        dispatch(saveEmail(data));
      })
      .catch(err => console.log(err));
  };
}

export function savePassword(password) {
  return {
    type: CHANGE_CURRENT_USER_PASSWORD,
    payload: password
  };
}

export function changePassword(passwrd) {
  return dispatch => {
    axios
      .post(CHANGE_USER_PASSWORD_PATH, {
        withCredentials: true,
        passwrd
      })
      .then(({ data }) => {
        dispatch(savePassword(data));
      })
      .catch(err => console.log(err));
  };
}

export function changeAvatar(avatarSrc) {
  return {
    type: CHANGE_CURRENT_USER_AVATAR,
    payload: avatarSrc
  };
}

export function saveTimezone({ timezone }) {
  return {
    type: CHANGE_CURRENT_USER_TIMEZONE,
    payload: timezone
  };
}

export function changeTimezone(timezone) {
  return dispatch => {
    axios
      .post(CHANGE_USER_TIMEZONE_PATH, { withCredentials: true, timezone })
      .then(({ data }) => {
        dispatch(saveTimezone(data));
      })
      .catch(err => console.log(err));
  };
}

export function saveAssignmentsNotification({ status }) {
  return {
    type: CHANGE_ASSIGNMENTS_NOTIFICATION,
    payload: status
  };
}

export function changeAssignmentsNotification(status) {
  return dispatch => {
    axios
      .post(CHANGE_USER_ASSIGNEMENTS_NOTIFICATION_PATH, {
        withCredentials: true,
        status
      })
      .then(({ data }) => {
        dispatch(saveAssignmentsNotification(data));
      })
      .catch(err => console.log(err));
  };
}

export function saveAssignmentsNotificationEmail({ status }) {
  return {
    type: CHANGE_ASSIGNMENTS_NOTIFICATION_EMAIL,
    payload: status
  };
}

export function changeAssignmentsNotificationEmail(status) {
  return dispatch => {
    axios
      .post(CHANGE_USER_ASSIGNMENTS_NOTIFICATION_EMAIL_PATH, {
        withCredentials: true,
        status
      })
      .then(({ data }) => {
        dispatch(saveAssignmentsNotificationEmail(data));
      })
      .catch(err => console.log(err));
  };
}

export function saveRecentNotification({ status }) {
  return {
    type: CHANGE_RECENT_NOTIFICATION,
    payload: status
  };
}

export function changeRecentNotification(status) {
  return dispatch => {
    axios
      .post(CHANGE_USER_RECENT_NOTIFICATION_PATH, {
        withCredentials: true,
        status
      })
      .then(({ data }) => {
        dispatch(saveRecentNotification(data));
      })
      .catch(err => console.log(err));
  };
}

export function saveRecentNotificationEmail({ status }) {
  return {
    type: CHANGE_RECENT_NOTIFICATION_EMAIL,
    payload: status
  };
}

export function changeRecentNotificationEmail(status) {
  return dispatch => {
    axios
      .post(CHANGE_USER_RECENT_NOTIFICATION_EMAIL_PATH, {
        withCredentials: true,
        status
      })
      .then(({ data }) => {
        dispatch(saveRecentNotificationEmail(data));
      })
      .catch(err => console.log(err));
  };
}

export function saveSystemMessageNotificationEmail({ status }) {
  return {
    type: CHANGE_SYSTEM_MESSAGE_NOTIFICATION_EMAIL,
    payload: status
  };
}

export function changeSystemMessageNotificationEmail(status) {
  return dispatch => {
    axios
      .post(CHANGE_USER_SYSTEM_MESSAGE_NOTIFICATION_EMAIL_PATH, {
        withCredentials: true,
        status
      })
      .then(({ data }) => {
        dispatch(saveSystemMessageNotificationEmail(data));
      })
      .catch(err => console.log(err));
  };
}
