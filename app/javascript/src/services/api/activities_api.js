// @flow
import { axiosInstance } from "./config";
import { ACTIVITIES_PATH } from "./endpoints";

export function getActivities(
  lastId: number = 0
): Promise<*> {
  const path = `${ACTIVITIES_PATH}?from=${lastId}`;
  return axiosInstance.get(path).then(({ data }) => data.global_activities);
}
