import axiosInstance from "./config";
import {
  USER_PROFILE_INFO,
  UPDATE_USER_PATH,
  CURRENT_USER_PATH,
  PREFERENCES_INFO_PATH,
  STATISTICS_INFO_PATH,
  SIGN_OUT_PATH
} from "./endpoints";

export const getUserProfileInfo = () =>
  axiosInstance.get(USER_PROFILE_INFO).then(({ data }) => data.user);

export const getUserPreferencesInfo = () =>
  axiosInstance.get(PREFERENCES_INFO_PATH).then(({ data }) => data);

export const updateUser = (params, formObj = false) => {
  if (formObj) {
    return axiosInstance
      .post(UPDATE_USER_PATH, params)
      .then(({ data }) => data.user);
  }
  return axiosInstance
    .post(UPDATE_USER_PATH, { user: params })
    .then(({ data }) => data.user);
};

export const getCurrentUser = () =>
  axiosInstance.get(CURRENT_USER_PATH).then(({ data }) => data.user);

export const getStatisticsInfo = () =>
  axiosInstance.get(STATISTICS_INFO_PATH).then(({ data }) => data.user);

export const signOutUser = () => axiosInstance.get(SIGN_OUT_PATH);
