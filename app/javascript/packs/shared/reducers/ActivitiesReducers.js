import {
  GLOBAL_ACTIVITIES_DATA,
  DESTROY_GLOBAL_ACTIVITIES_DATA
} from "../../app/action_types";

const initialStateu = { more: true, activities: [] };

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
    default:
      return state;
  }
}
