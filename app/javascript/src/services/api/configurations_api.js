// @flow
import axiosInstance from "./config";
import { ABOUT_SCINOTE_PATH } from "./endpoints";

export const getSciNoteInfo = (): Promise<*> =>
  axiosInstance.get(ABOUT_SCINOTE_PATH).then(({ data }) => data);
