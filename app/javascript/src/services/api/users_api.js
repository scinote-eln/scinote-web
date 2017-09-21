import { axiosInstance, ResponseError } from "./config";
import { USER_PROFILE_INFO, UPDATE_USER_PATH } from "./endpoints";

export const getUserProfileInfo = () => {
  return axiosInstance.get(USER_PROFILE_INFO).then(({ data }) => data.user);
};

export const updateUser = data => {
  return axiosInstance
    .post(UPDATE_USER_PATH, { user: data })
    .then(({ data }) => data.user);
};
