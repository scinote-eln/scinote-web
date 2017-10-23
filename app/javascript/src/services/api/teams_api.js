//  @flow
import type { Teams$NewTeam, Team$Update } from "flow-typed";
import { axiosInstance } from "./config";
import { TEAM_DETAILS_PATH, TEAMS_PATH, TEAM_UPDATE_PATH } from "./endpoints";

export const getTeamDetails = (teamID: number): Promise<*> => {
  const path = TEAM_DETAILS_PATH.replace(":team_id", teamID);
  return axiosInstance.get(path).then(({ data }) => data.team_details);
};

export const createNewTeam = (team: Teams$NewTeam): Promise<*> =>
  axiosInstance.post(TEAMS_PATH, { team }).then(({ data }) => data);

export const updateTeam = (teamID: number, teamData: Team$Update): Promise<*> =>
  axiosInstance
    .post(TEAM_UPDATE_PATH, { team_id: teamID, team: teamData })
    .then(({ data }) => data.team);
