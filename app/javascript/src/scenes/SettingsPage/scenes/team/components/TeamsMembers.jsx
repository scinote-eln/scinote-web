import React, { Component } from "react";
import PropTypes, { number, func, string, bool } from "prop-types";
import {
  Panel,
  Button,
  Glyphicon,
  DropdownButton,
  MenuItem
} from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import axios from "../../../../../config/axios";

import InviteUsersModal from "../../../../../components/InviteUsersModal";
import RemoveUserModal from "./RemoveUserModal";
import DataTable from "../../../../../components/data_table";
import { UPDATE_USER_TEAM_ROLE_PATH } from "../../../../../config/api_endpoints";

const initalUserToRemove = {
  userName: "",
  team_user_id: 0,
  teamName: "",
  team_id: 0
};
class TeamsMembers extends Component {
  constructor(params) {
    super(params);
    this.state = {
      showModal: false,
      showInviteUsersModal: false,
      userToRemove: initalUserToRemove
    };
    this.memberAction = this.memberAction.bind(this);
    this.showInviteUsersModalCallback = this.showInviteUsersModalCallback.bind(
      this
    );
    this.closeInviteUsersModalCallback = this.closeInviteUsersModalCallback.bind(
      this
    );
    this.hideModal = this.hideModal.bind(this);
  }

  currentRole(memberRole, role) {
    return memberRole === role ? <Glyphicon glyph="ok" /> : "  ";
  }

  updateRole(userTeamId, role) {
    axios
      .put(UPDATE_USER_TEAM_ROLE_PATH, {
        team: this.props.team.id,
        user_team: userTeamId,
        role
      })
      .then(response => {
        this.props.updateUsersCallback(response.data.team_users);
      })
      .catch(error => console.log(error));
  }

  showInviteUsersModalCallback() {
    this.setState({ showInviteUsersModal: true });
  }

  closeInviteUsersModalCallback() {
    this.setState({ showInviteUsersModal: false });
  }

  hideModal() {
    this.setState({ showModal: false, userToRemove: initalUserToRemove });
  }

  userToRemove(userToRemove) {
    this.setState({ showModal: true, userToRemove });
  }

  memberAction(data, row) {
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
            this.updateRole(data.team_user_id, 0);
          }}
        >
          {this.currentRole(data.current_role, "Guest")}
          <FormattedMessage id="settings_page.single_team.actions.guest" />
        </MenuItem>
        <MenuItem
          onSelect={() => {
            // 1 => Normal user
            this.updateRole(data.team_user_id, 1);
          }}
        >
          {this.currentRole(data.current_role, "Normal user")}
          <FormattedMessage id="settings_page.single_team.actions.normal_user" />
        </MenuItem>
        <MenuItem
          onSelect={() => {
            // 2 => Administrator
            this.updateRole(data.team_user_id, 2);
          }}
        >
          {this.currentRole(data.current_role, "Administrator")}
          <FormattedMessage id="settings_page.single_team.actions.administrator" />
        </MenuItem>
        <MenuItem divider />
        <MenuItem
          onClick={() => {
            this.userToRemove({
              userName: row.name,
              team_user_id: data.team_user_id,
              teamName: this.props.team.name,
              team_id: this.props.team.id
            });
          }}
        >
          <FormattedMessage id="settings_page.single_team.actions.remove_user" />
        </MenuItem>
      </DropdownButton>
    );
  }

  render() {
    const columns = [
      {
        id: 1,
        name: "Name",
        isKey: false,
        textId: "name",
        position: 0,
        dataSort: true
      },
      {
        id: 2,
        name: "Email",
        isKey: true,
        textId: "email",
        position: 1,
        dataSort: true
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
        position: 3
      },
      {
        id: 5,
        name: "Status",
        isKey: false,
        textId: "status",
        position: 3
      },
      {
        id: 6,
        name: "Actions",
        isKey: false,
        textId: "actions",
        columnClassName: "react-bootstrap-table-dropdown-fix",
        dataFormat: this.memberAction,
        position: 3
      }
    ];

    return (
      <Panel
        header={
          <FormattedMessage id="settings_page.single_team.members_panel_title" />
        }
      >
        <Button bsStyle="primary" onClick={this.showInviteUsersModalCallback}>
          <Glyphicon glyph="plus" />
          <FormattedMessage id="settings_page.single_team.add_members" />
        </Button>

        <DataTable data={this.props.members} columns={columns} />
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

TeamsMembers.propTypes = {
  updateUsersCallback: func.isRequired,
  team: PropTypes.shape({
    id: number.isRequired,
    name: string.isRequired
  }).isRequired,
  members: PropTypes.arrayOf(
    PropTypes.shape({
      id: number.isRequired,
      name: string.isRequired,
      email: string.isRequired,
      role: string.isRequired,
      created_at: string.isRequired,
      status: string.isRequired,
      actions: PropTypes.shape({
        current_role: string.isRequired,
        team_user_id: number.isRequired,
        disable: bool.isRequired
      })
    }).isRequired
  ).isRequired
};

export default TeamsMembers;
