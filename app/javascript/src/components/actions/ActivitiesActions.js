import axios from "../../config/axios";
import { ACTIVITIES_PATH } from "../../config/api_endpoints";
import {
  GLOBAL_ACTIVITIES_DATA,
  DESTROY_GLOBAL_ACTIVITIES_DATA,
  SPINNER_ON,
  SPINNER_OFF
} from "../../config/action_types";

function addActivitiesData(data) {
  return {
    type: GLOBAL_ACTIVITIES_DATA,
    payload: data
  };
}

export function destroyActivities() {
  return {
    type: DESTROY_GLOBAL_ACTIVITIES_DATA
  };
}

export function getActivities(lastId = 0) {
  return dispatch => {
    const path = `${ACTIVITIES_PATH}?from=${lastId}`;
    axios
      .get(path, { withCredentials: true })
      .then(response => {
        dispatch(addActivitiesData(response.data));
      })
      .catch(error => {
        console.log("get Activites Error: ", error);
      });
  };
}

export function spinnerOn() {
  return {
    type: SPINNER_ON
  };
}

export function spinnerOff() {
  return {
    type: SPINNER_OFF
  };
}
