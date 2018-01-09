// @flow
import axiosInstance from "./config";
import { ACTIVITIES_PATH } from "./endpoints";

export function getActivities(
  page: number = 1
): Promise<*> {
  const path = `${ACTIVITIES_PATH}?page=${page}`;
  return axiosInstance.get(path).then(({ data }) => data.global_activities);
}

export default 'getActivities';
