import {
  GLOBAL_ACTIVITIES_DATA,
  MORE_GLOBAL_ACTIVITIES
} from "../actions/types";

export function globalActivities(
  state = { more: true, activities: [] },
  action
) {
  if (action.type === GLOBAL_ACTIVITIES_DATA) {
    return {
      ...state,
      activities: [
        ...state.activities,
        ...action.payload.global_activities.activities
      ],
      more: action.payload.global_activities.more
    };
  }
  return state;
}
