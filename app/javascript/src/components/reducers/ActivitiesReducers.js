import {
  GLOBAL_ACTIVITIES_DATA,
  DESTROY_GLOBAL_ACTIVITIES_DATA,
  SPINNER_OFF,
  SPINNER_ON
} from "../../config/action_types";

const initialStateu = { more: true, activities: [], spinner_on: false };

export function globalActivities(state = initialStateu, action) {
  switch (action.type) {
    case GLOBAL_ACTIVITIES_DATA:
      return {
        ...state,
        activities: [
          ...state.activities,
          ...action.payload.global_activities.activities
        ],
        more: action.payload.global_activities.more
      };
    case DESTROY_GLOBAL_ACTIVITIES_DATA:
      return {
        ...state,
        ...initialStateu
      };
    case SPINNER_OFF:
      return Object.assign({}, state, { spinner_on: false });
    case SPINNER_ON:
      return Object.assign({}, state, { spinner_on: true });
    default:
      return state;
  }
}
