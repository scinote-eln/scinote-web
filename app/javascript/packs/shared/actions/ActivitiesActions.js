import axios from "axios";
import { ACTIVITIES_PATH } from "../../app/routes";
import { GLOBAL_ACTIVITIES_DATA } from "../../app/action_types";

function addActivitiesData(data) {
  return {
    type: GLOBAL_ACTIVITIES_DATA,
    payload: data
  };
}

export function getActivities(last_id = 0) {
  return dispatch => {
    let path = `${ACTIVITIES_PATH}?from=${last_id}`;
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
