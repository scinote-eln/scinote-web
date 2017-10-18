//  @flow

import { axiosInstance } from "./config";
import { REMOVE_USER_FROM_TEAM_PATH, INVITE_USERS_PATH } from "./endpoints";

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

export const inviteUsersToTeam = (
  role: number,
  emails: Array<string>,
  teamID: number
): Promise<*> => {
  return axiosInstance
    .put(INVITE_USERS_PATH, {
      user_role: role,
      team_id: teamID,
      emails
    })
    .then(({ data }) => data);
};
