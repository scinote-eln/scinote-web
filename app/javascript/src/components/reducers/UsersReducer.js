import {
  SET_CURRENT_USER,
  CHANGE_CURRENT_USER_TIMEZONE,
  CHANGE_ASSIGNMENTS_NOTIFICATION,
  CHANGE_ASSIGNMENTS_NOTIFICATION_EMAIL,
  CHANGE_RECENT_NOTIFICATION,
  CHANGE_RECENT_NOTIFICATION_EMAIL,
  CHANGE_SYSTEM_MESSAGE_NOTIFICATION_EMAIL
} from "../../config/action_types";

export function currentUser(
  state = {
    id: 0,
    fullName: "",
    initials: "",
    email: "",
    avatarPath: "",
    avatarThumbPath: "",
    timezone: "",
    assignmentsNotification: false,
    assignmentsNotificationEmail: false,
    recentNotification: false,
    recentNotificationEmail: false,
    systemMessageNotificationEmail: false
  },
  action
) {
  switch (action.type) {
    case SET_CURRENT_USER:
      return Object.assign({}, state, action.payload);
    case CHANGE_CURRENT_USER_TIMEZONE:
      return Object.assign({}, state, { timezone: action.payload });
    case CHANGE_ASSIGNMENTS_NOTIFICATION:
      return Object.assign({}, state, {
        assignmentsNotification: action.payload
      });
    case CHANGE_ASSIGNMENTS_NOTIFICATION_EMAIL:
      return Object.assign({}, state, {
        assignmentsNotificationEmail: action.payload
      });
    case CHANGE_RECENT_NOTIFICATION:
      return Object.assign({}, state, { recentNotification: action.payload });
    case CHANGE_RECENT_NOTIFICATION_EMAIL:
      return Object.assign({}, state, {
        recentNotificationEmail: action.payload
      });
    case CHANGE_SYSTEM_MESSAGE_NOTIFICATION_EMAIL:
      return Object.assign({}, state, {
        systemMessageNotificationEmail: action.payload
      });
    default:
      return state;
  }
}
