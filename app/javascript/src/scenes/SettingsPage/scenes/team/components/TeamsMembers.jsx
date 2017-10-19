// @flow
import React, { Component } from "react";
import type { Node } from "react";
import {
  Row,
  Panel,
  Button,
  Glyphicon,
  DropdownButton,
  MenuItem
} from "react-bootstrap";
import styled from "styled-components";
import type { Teams$TeamMember, Team$TeamMemeber, Teams$TeamMemberActions } from "flow-typed";

import { FormattedMessage } from "react-intl";
import { updateUserTeamRole } from "../../../../../services/api/user_team_api";
import InviteUsersModal from "../../../../../components/InviteUsersModal";
import RemoveUserModal from "./RemoveUserModal";
import DataTable from "../../../../../components/data_table";

const StyledButton = styled(Button)`
  margin-bottom: 10px;
  margin-right: 15px;
`;

const initalUserToRemove = {
  userName: "",
  teamUserId: 0,
  teamName: "",
  teamId: 0
};

type Team = {
  id: number,
  name: string
};

type TableColumns = {
  name: string,
  email: string,
  role: number,
  created_at: string,
  status: string,
  actuons: Teams$TeamMemberActions
}

type Props = {
  updateUsersCallback: Function,
  team: Team,
  members: Array<Teams$TeamMember>
};

type State = {
  showModal: boolean,
  showInviteUsersModal: boolean,
  userToRemove: Team$TeamMemeber
};

class TeamsMembers extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      showModal: false,
      showInviteUsersModal: false,
      userToRemove: initalUserToRemove
    };
    (this: any).memberAction = this.memberAction.bind(this);
    (this: any).showInviteUsersModalCallback = this.showInviteUsersModalCallback.bind(
      this
    );
    (this: any).closeInviteUsersModalCallback = this.closeInviteUsersModalCallback.bind(
      this
    );
    (this: any).hideModal = this.hideModal.bind(this);
  }

  currentRole(memberRole: string, role: string): Node {
    return memberRole === role ? <Glyphicon glyph="ok" /> : <span />;
  }

  updateRole(userTeamId: number, role: number): void {
    updateUserTeamRole(this.props.team.id, userTeamId, role)
      .then(response => {
        this.props.updateUsersCallback(response);
      })
      .catch(error => console.log(error));
  }

  showInviteUsersModalCallback(): void {
    (this: any).setState({ showInviteUsersModal: true });
  }

  closeInviteUsersModalCallback(): void {
    (this: any).setState({ showInviteUsersModal: false });
  }

  hideModal(): void {
    (this: any).setState({
      showModal: false,
      userToRemove: initalUserToRemove
    });
  }

  userToRemove(userToRemove: Teams$TeamMemberActions): void {
    (this: any).setState({ showModal: true, userToRemove });
  }

  memberAction(data: Teams$TeamMemberActions, row: TableColumns): Node {
    return (
      <DropdownButton
        bsStyle="default"
        disabled={data.disable}
        title={
          <span>
            <Glyphicon glyph="cog" />
          </span>
        }
        id="actions-dropdown"
      >
        <MenuItem header>
          <FormattedMessage id="settings_page.single_team.actions.user_role" />
        </MenuItem>
        <MenuItem
          onSelect={() => {
            // 0 => Guest
            this.updateRole(data.teamUserId, 0);
          }}
        >
          {this.currentRole(data.currentRole, "Guest")}
          <FormattedMessage id="settings_page.single_team.actions.guest" />
        </MenuItem>
        <MenuItem
          onSelect={() => {
            // 1 => Normal user
            this.updateRole(data.teamUserId, 1);
          }}
        >
          {this.currentRole(data.currentRole, "Normal user")}
          <FormattedMessage id="settings_page.single_team.actions.normal_user" />
        </MenuItem>
        <MenuItem
          onSelect={() => {
            // 2 => Administrator
            this.updateRole(data.teamUserId, 2);
          }}
        >
          {this.currentRole(data.currentRole, "Administrator")}
          <FormattedMessage id="settings_page.single_team.actions.administrator" />
        </MenuItem>
        <MenuItem divider />
        <MenuItem
          onClick={() => {
            this.userToRemove({
              userName: row.name,
              teamUserId: data.teamUserId,
              teamName: this.props.team.name,
              teamId: this.props.team.id
            });
          }}
        >
          <FormattedMessage id="settings_page.single_team.actions.remove_user" />
        </MenuItem>
      </DropdownButton>
    );
  }

  render() {
    const options = {
      sizePerPageList: [10, 25, 50, 100],
      prePage: "Prev", // Previous page button text
      nextPage: "Next", // Next page button textu
      paginationShowsTotal: DataTable.renderShowsTotal,
      alwaysShowAllBtns: true
    };

    const columns = [
      {
        id: 1,
        name: "Name",
        isKey: false,
        textId: "name",
        position: 0,
        dataSort: true,
        width: "25%"
      },
      {
        id: 2,
        name: "Email",
        isKey: true,
        textId: "email",
        position: 1,
        dataSort: true,
        width: "30%"
      },
      {
        id: 3,
        name: "Role",
        isKey: false,
        textId: "role",
        position: 2,
        dataSort: true
      },
      {
        id: 4,
        name: "Joined on",
        isKey: false,
        textId: "created_at",
        position: 3,
        dataSort: true
      },
      {
        id: 5,
        name: "Status",
        isKey: false,
        textId: "status",
        position: 3,
        dataSort: true
      },
      {
        id: 6,
        name: "Actions",
        isKey: false,
        textId: "actions",
        columnClassName: "react-bootstrap-table-dropdown-fix",
        dataFormat: this.memberAction,
        position: 3,
        width: "80px"
      }
    ];

    return (
      <Panel
        header={
          <FormattedMessage id="settings_page.single_team.members_panel_title" />
        }
      >
        <Row>
          <StyledButton
            bsStyle="primary"
            className="pull-right"
            onClick={this.showInviteUsersModalCallback}
          >
            <Glyphicon glyph="plus" />
            <FormattedMessage id="settings_page.single_team.add_members" />
          </StyledButton>
        </Row>

        <DataTable
          data={this.props.members}
          columns={columns}
          pagination
          search
          options={options}
        />
        <RemoveUserModal
          showModal={this.state.showModal}
          hideModal={this.hideModal}
          updateUsersCallback={this.props.updateUsersCallback}
          userToRemove={this.state.userToRemove}
        />
        <InviteUsersModal
          showModal={this.state.showInviteUsersModal}
          onCloseModal={this.closeInviteUsersModalCallback}
          team={this.props.team}
          updateUsersCallback={this.props.updateUsersCallback}
        />
      </Panel>
    );
  }
}

export default TeamsMembers;
