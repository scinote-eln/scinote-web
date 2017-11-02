//  @flow
import type { Teams$NewTeam, Team$Update } from "flow-typed";
import _ from "lodash";
import axiosInstance from "./config";
import {
  TEAM_DETAILS_PATH,
  TEAM_UPDATE_PATH,
  TEAMS_PATH,
  CHANGE_TEAM_PATH,
  LEAVE_TEAM_PATH
} from "./endpoints";

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

export const getTeams = (): Promise<*> =>
  axiosInstance.get(TEAMS_PATH).then(({ data }) => {
    const teams = data.teams.collection;
    const currentTeam = _.find(teams, team => team.current_team);
    return { teams, currentTeam };
  });

export const changeCurrentTeam = (teamID: number): Promise<*> =>
  axiosInstance.post(CHANGE_TEAM_PATH, { team_id: teamID }).then(({ data }) => {
    const teams = data.teams.collection;
    const currentTeam = _.find(teams, team => team.current_team);
    return { teams, currentTeam };
  });

export const leaveTeam = (teamID: number, userTeamID: number): Promise<*> => {
  const teamUrl = `${LEAVE_TEAM_PATH}?team=${teamID}&user_team=${userTeamID}`;
  return axiosInstance.delete(teamUrl).then(({ data }) => {
    const teams = data.teams.collection;
    const currentTeam = _.find(teams, team => team.current_team);
    return { teams, currentTeam };
  });
};
