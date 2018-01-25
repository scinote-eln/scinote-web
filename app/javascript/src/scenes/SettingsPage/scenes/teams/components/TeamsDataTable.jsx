// @flow
import React, { Component } from "react";
import type { Node } from "react";
import type { Teams$Team } from "flow-typed";
import { Button } from "react-bootstrap";
import { Link } from "react-router-dom";
import { FormattedMessage } from "react-intl";
import DataTable from "../../../../../components/data_table";
import { SETTINGS_TEAMS_ROUTE } from "../../../../../config/routes";
import LeaveTeamModal from "./LeaveTeamModal";

const DefaultTeam = {
  id: 0,
  name: "",
  user_team_id: 0,
  role: "",
  members: 0,
  can_be_left: false
};

type Props = {
  updateTeamsState: Function,
  teams: Array<Teams$Team>,
  sizePerPage: number,
  onSizePerPageList: Function
};

type State = {
  leaveTeamModalShow: boolean,
  team: Teams$Team
};

class TeamsDataTable extends Component<Props, State> {
  static linkToTeam(name: string, team: Teams$Team): Node {
    return <Link to={`${SETTINGS_TEAMS_ROUTE}/${team.id}`}>{name}</Link>;
  }

  constructor(props: Props) {
    super(props);
    this.state = {
      leaveTeamModalShow: false,
      team: DefaultTeam
    };
    (this: any).leaveTeamModal = this.leaveTeamModal.bind(this);
    (this: any).leaveTeamButton = this.leaveTeamButton.bind(this);
    (this: any).hideLeaveTeamModal = this.hideLeaveTeamModal.bind(this);
  }

  leaveTeamModal(e: string, team: Teams$Team): void {
    (this: any).setState({ leaveTeamModalShow: true, team });
  }

  hideLeaveTeamModal(): void {
    (this: any).setState({ leaveTeamModalShow: false, team: DefaultTeam });
  }

  leaveTeamButton(id: string, team: Teams$Team): Node {
    if (team.can_be_left) {
      return (
        <Button onClick={e => this.leaveTeamModal(e, team)}>
          <FormattedMessage id="settings_page.leave_team" />
        </Button>
      );
    }
    return (
      <Button disabled>
        <FormattedMessage id="settings_page.leave_team" />
      </Button>
    );
  }

  render(): Node {
    const options = {
      defaultSortName: "name",
      defaultSortOrder: "desc",
      sizePerPageList: [10, 25, 50, 100],
      sizePerPage: this.props.sizePerPage,
      onSizePerPageList: this.props.onSizePerPageList,
      prePage: "Prev", // Previous page button text
      nextPage: "Next", // Next page button textu
      paginationShowsTotal: DataTable.renderShowsTotal,
      alwaysShowAllBtns: true
    };
    const columns = [
      {
        id: 1,
        name: "Team",
        isKey: false,
        textId: "name",
        dataFormat: TeamsDataTable.linkToTeam,
        position: 0,
        dataSort: true,
        width: "50%"
      },
      {
        id: 2,
        name: "Role",
        isKey: false,
        textId: "role",
        position: 1,
        dataSort: true,
        width: "35%"
      },
      {
        id: 3,
        name: "Members",
        isKey: false,
        textId: "members",
        position: 2,
        dataSort: true,
        width: "15%"
      },
      {
        id: 4,
        name: "",
        isKey: true,
        textId: "id",
        dataFormat: this.leaveTeamButton,
        position: 3,
        width: "116px"
      }
    ];
    return (
      <div>
        <DataTable
          data={this.props.teams}
          columns={columns}
          pagination
          options={options}
        />
        <LeaveTeamModal
          updateTeamsState={this.props.updateTeamsState}
          showModal={this.state.leaveTeamModalShow}
          team={this.state.team}
          hideLeaveTeamModal={this.hideLeaveTeamModal}
        />
      </div>
    );
  }
}

export default TeamsDataTable;
