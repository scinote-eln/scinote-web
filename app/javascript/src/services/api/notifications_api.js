import axiosInstance from "./config";
import {
  RECENT_NOTIFICATIONS_PATH,
  UNREADED_NOTIFICATIONS_PATH
} from "./endpoints";

export const getRecentNotifications = () => {
  return axiosInstance.get(RECENT_NOTIFICATIONS_PATH).then(({ data }) => data);
};

export const getUnreadNotificationsCount = () => {
  return axiosInstance
    .get(UNREADED_NOTIFICATIONS_PATH)
    .then(({ data }) => data);
};
