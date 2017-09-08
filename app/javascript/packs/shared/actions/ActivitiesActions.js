import axios from "../../app/axios";
import { ACTIVITIES_PATH } from "../../app/routes";
import {
  GLOBAL_ACTIVITIES_DATA,
  DESTROY_GLOBAL_ACTIVITIES_DATA,
  GLOBAL_FLASH_MSG
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

export function closeFlashMsg() {
  return {
    type: GLOBAL_FLASH_MSG,
    payload: { text: "Success!", type: "success", isEnabled: false }
  };
}

export function showFlashMsg(text = "Sucess!", type = "success") {
  return {
    type: GLOBAL_FLASH_MSG,
    payload: { text, type, isEnabled: true }
  };
}
