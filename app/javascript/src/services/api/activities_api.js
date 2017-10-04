import { axiosInstance } from "./config";
import { ACTIVITIES_PATH } from "./endpoints";

export function getActivities(lastId = 0) {
  const path = `${ACTIVITIES_PATH}?from=${lastId}`;
  axiosInstance.get(path).then(({ data }) => data);
}
