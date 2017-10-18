//  @flow
import { axiosInstance } from "./config";
import { TEAM_DETAILS_PATH, TEAMS_PATH } from "./endpoints";
import type { NewTeam } from "flow-typed";

export const getTeamDetails = (teamID: string): Promise<*> => {
  const path = TEAM_DETAILS_PATH.replace(":team_id", teamID);
  return axiosInstance.get(path).then(({ data }) => data.team_details);
};

export const createNewTeam = (team: NewTeam): Promise<*> =>
  axiosInstance.post(TEAMS_PATH, { team }).then(({ data }) => data);
