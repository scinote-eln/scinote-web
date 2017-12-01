//  @flow

import axiosInstance from "./config";
import { PERMISSIONS_PATH } from "./endpoints";

export const getPermissionStatus = (
  requiredPermissions: Array<string>,
  resource: string
): Promise<*> => {
  const parsePermission = requiredPermissions.map(el => el.replace("?", ""));
  return axiosInstance
    .post(PERMISSIONS_PATH, {
      parsePermission,
      resource
    })
    .then(({ data }) => data);
};
