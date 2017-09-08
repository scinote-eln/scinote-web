import {
  GLOBAL_ACTIVITIES_DATA,
  DESTROY_GLOBAL_ACTIVITIES_DATA,
  GLOBAL_FLASH_MSG
} from "../../app/action_types";

const initialStateu = {
  more: true,
  activities: [],
  flash_msg: { text: "default msg", type: "success", isEnabled: false }
};

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
    case GLOBAL_FLASH_MSG:
      const msg = Object.assign({}, state.flash_msg, action.payload);
      const newState = Object.assign({}, state, { flash_msg: msg });

      return newState;
    default:
      return state;
  }
}
