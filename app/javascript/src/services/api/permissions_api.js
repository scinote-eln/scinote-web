//  @flow

import axiosInstance from "./config";
import { PERMISSIONS_PATH } from "./endpoints";

export const getPermissionStatus = (
  requiredPermissions: Array<string>,
  resource: string
): Promise<*> => {
  return axiosInstance
    .get(PERMISSIONS_PATH, {
      requiredPermissions,
      resource
    })
    .then(({ data }) => data);
};
