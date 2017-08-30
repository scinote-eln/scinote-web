import React, { Component } from "react";
import PropTypes, { func, number, string, bool } from "prop-types";
import { connect } from "react-redux";
import { Button } from "react-bootstrap";
import _ from "lodash";
import { Link } from "react-router-dom";
import { FormattedMessage } from "react-intl";
import { leaveTeamModalShow } from "../../../../../shared/actions/LeaveTeamActions";
import DataTable from "../../../../../shared/data_table";
import { SETTINGS_TEAMS_ROUTE } from "../../../../../app/dom_routes";

class TeamsDataTable extends Component {
  constructor(props) {
    super(props);

    this.leaveTeamModal = this.leaveTeamModal.bind(this);
    this.leaveTeamButton = this.leaveTeamButton.bind(this);
    this.linkToTeam = this.linkToTeam.bind(this);
  }

  leaveTeamModal(e, id) {
    const team = _.find(this.props.teams, el => el.id === id);
    this.props.leaveTeamModalShow(true, id, team.name);
  }

  leaveTeamButton(id) {
    const team = _.find(this.props.teams, el => el.id === id);
    if (team.can_be_leaved) {
      return (
        <Button onClick={e => this.leaveTeamModal(e, id)}>
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

  linkToTeam(name, col) {
    return (
      <Link to={`${SETTINGS_TEAMS_ROUTE}/${col.id}`}>
        {name}
      </Link>
    );
  }

  render() {
    const options = {
      defaultSortName: "name",
      defaultSortOrder: "desc",
      sizePerPageList: [10, 25, 50, 100],
      paginationPosition: "top",
      alwaysShowAllBtns: false
    };
    const columns = [
      {
        id: 1,
        name: "Name",
        isKey: false,
        textId: "name",
        dataFormat: this.linkToTeam,
        position: 0,
        dataSort: true
      },
      {
        id: 2,
        name: "Role",
        isKey: false,
        textId: "role",
        position: 1,
        dataSort: true
      },
      {
        id: 3,
        name: "Members",
        isKey: false,
        textId: "members",
        position: 2,
        dataSort: true
      },
      {
        id: 4,
        name: "",
        isKey: true,
        textId: "id",
        dataFormat: this.leaveTeamButton,
        position: 3
      }
    ];
    return (
      <DataTable
        data={this.props.teams}
        columns={columns}
        pagination={true}
        options={options}
      />
    );
  }
}

TeamsDataTable.propTypes = {
  leaveTeamModalShow: func.isRequired,
  teams: PropTypes.arrayOf(
    PropTypes.shape({
      id: number.isRequired,
      name: string.isRequired,
      current_team: bool.isRequired,
      role: string.isRequired,
      members: number.isRequired,
      can_be_leaved: bool.isRequired
    }).isRequired
  )
};

export default connect(null, { leaveTeamModalShow })(TeamsDataTable);
