import axios from "../../app/axios";
import { ACTIVITIES_PATH } from "../../app/routes";
import {
  GLOBAL_ACTIVITIES_DATA,
  DESTROY_GLOBAL_ACTIVITIES_DATA
} from "../../app/action_types";

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
