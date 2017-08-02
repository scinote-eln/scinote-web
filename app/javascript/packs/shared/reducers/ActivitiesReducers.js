import {
  GLOBAL_ACTIVITIES_DATA,
  MORE_GLOBAL_ACTIVITIES
} from "../actions/types";

export function globalActivities(state = [], action) {
  if (action.type === GLOBAL_ACTIVITIES_DATA) {
    return Object.assign([], state, action.payload, {
      last_payload: () => action.payload.lenght < 10
    });
  }
  return state;
}
