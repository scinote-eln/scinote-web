//  @flow
import { axiosInstance } from "./config";
import { REMOVE_USER_FROM_TEAM_PATH } from "./endpoints";

export const removeUserFromTeam = (
  teamId: number,
  teamUserId: number
): Promise<*> => {
  return axiosInstance({
    method: "DELETE",
    url: REMOVE_USER_FROM_TEAM_PATH,
    data: {
      team: teamId,
      user_team: teamUserId
    }
  }).then(({ data }) => data.team_users);
};
