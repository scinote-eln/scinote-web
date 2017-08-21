import axios from "../../app/axios";
import { CURRENT_USER_PATH } from "../../app/routes";
import { SET_CURRENT_USER } from "../../app/action_types";

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
