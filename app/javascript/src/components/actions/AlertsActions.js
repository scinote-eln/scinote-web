import shortid from "shortid";
import {
  ADD_ALERT,
  CLEAR_ALERT,
  CLEAR_ALL_ALERTS
} from "../../config/action_types";

export function addAlert(message,
                         type,
                         id = shortid.generate(),
                         timeout = 5000) {
  return {
    payload: {
      message,
      type,
      id,
      timeout
    },
    type: ADD_ALERT
  };
}

export function clearAlert(id) {
  return { payload: id, type: CLEAR_ALERT }
}

export function clearAllAlerts() {
  return { type: CLEAR_ALL_ALERTS };
}