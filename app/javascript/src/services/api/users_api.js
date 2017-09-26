import { axiosInstance } from "./config";
import { USER_PROFILE_INFO, UPDATE_USER_PATH } from "./endpoints";

export const getUserProfileInfo = () => {
  return axiosInstance.get(USER_PROFILE_INFO).then(({ data }) => data.user);
};

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
