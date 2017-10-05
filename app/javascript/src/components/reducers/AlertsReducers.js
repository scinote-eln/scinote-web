import {
  ADD_ALERT,
  CLEAR_ALERT,
  CLEAR_ALL_ALERTS
} from "../../config/action_types";

export const alerts = (
  state = [],
  action
) => {
  switch(action.type) {
    case ADD_ALERT:
      return [
        ...state,
        {
          message: action.payload.message,
          type: action.payload.type,
          id: action.payload.id,
          timeout: action.payload.timeout
        }
      ];
    case CLEAR_ALERT:
      return state.filter((alert) => (
        alert.id !== action.payload
      ));
    case CLEAR_ALL_ALERTS:
      return [];
    default:
      return state;
  }
};