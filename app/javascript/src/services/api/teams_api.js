//  @flow

import { axiosInstance } from "./config";
import { TEAM_DETAILS_PATH } from "./endpoints";

export const getTeamDetails = (teamID: number): Promise<*> => {
  const path = TEAM_DETAILS_PATH.replace(":team_id", teamID);
  return axiosInstance.get(path).then(({ data }) => data.team_details);
};
