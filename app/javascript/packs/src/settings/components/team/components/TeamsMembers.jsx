import React, { Component } from "react";
import PropTypes from "prop-types";
import {
  Panel,
  Button,
  Glyphicon,
  DropdownButton,
  MenuItem
} from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import DataTable from "../../../../../shared/data_table";

class TeamsMembers extends Component {
  constructor(params) {
    super(params);
    this.memberAction = this.memberAction.bind(this);
  }

  currentRole(memberRole, role) {
    return memberRole === role ? <Glyphicon glyph="ok" /> : "  ";
  }

  memberAction(data, row) {
    return (
      <DropdownButton bsStyle="default" title={"banana"} id="actions-dropdown">
        <MenuItem className="dropdown-header" disabled>
          <FormattedMessage id="settings_page.single_team.actions.user_role" />
        </MenuItem>
        <MenuItem
          onSelect={() => {
            this.props.updateRole(data.team_user_id, "Guest");
          }}
        >
          {this.currentRole(data.current_role, "Guest")}
          <FormattedMessage id="settings_page.single_team.actions.guest" />
        </MenuItem>
        <MenuItem
          onSelect={() => {
            this.props.updateRole(data.team_user_id, "Normal user");
          }}
        >
          {this.currentRole(data.current_role, "Normal user")}
          <FormattedMessage id="settings_page.single_team.actions.normal_user" />
        </MenuItem>
        <MenuItem
          onSelect={() => {
            this.props.updateRole(data.team_user_id, "Administrator");
          }}
        >
          {this.currentRole(data.current_role, "Administrator")}
          <FormattedMessage id="settings_page.single_team.actions.administrator" />
        </MenuItem>
        <MenuItem divider />
        <MenuItem
          onSelect={() => {
            this.props.removeUser;
            data.team_user_id;
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
        <Button>
          <Glyphicon glyph="plus" />
          <FormattedMessage id="settings_page.single_team.add_members" />
        </Button>

        <DataTable data={this.props.members} columns={columns} />
      </Panel>
    );
  }
}

export default TeamsMembers;
