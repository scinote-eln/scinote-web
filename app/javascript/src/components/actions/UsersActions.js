import axios from "../../config/axios";

import {
  SET_CURRENT_USER,
} from "../../config/action_types";

export function addCurrentUser(data) {
  return {
    type: SET_CURRENT_USER,
    payload: data
  };
}
