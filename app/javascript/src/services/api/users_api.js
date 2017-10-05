import { axiosInstance } from "./config";
import { SIGN_OUT_PATH } from "./endpoints";

export function signOutUser() {
  return axiosInstance.get(SIGN_OUT_PATH);
}
