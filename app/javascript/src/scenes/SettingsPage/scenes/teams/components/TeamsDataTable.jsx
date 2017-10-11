import React, { Component } from "react";
import PropTypes, { func, number, string, bool } from "prop-types";
import { connect } from "react-redux";
import { Button } from "react-bootstrap";
import { Link } from "react-router-dom";
import { FormattedMessage } from "react-intl";
import { leaveTeamModalShow } from "../../../../../components/actions/TeamsActions";
import DataTable from "../../../../../components/data_table";
import { SETTINGS_TEAMS_ROUTE } from "../../../../../config/routes";

class TeamsDataTable extends Component {
  constructor(props) {
    super(props);

    this.leaveTeamModal = this.leaveTeamModal.bind(this);
    this.leaveTeamButton = this.leaveTeamButton.bind(this);
    this.linkToTeam = this.linkToTeam.bind(this);
  }

  leaveTeamModal(e, team) {
    this.props.leaveTeamModalShow(true, team);
  }

  leaveTeamButton(id, team) {
    if (team.can_be_leaved) {
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

  linkToTeam(name, row) {
    return <Link to={`${SETTINGS_TEAMS_ROUTE}/${row.id}`}>{name}</Link>;
  }

  render() {
    const options = {
      defaultSortName: "name",
      defaultSortOrder: "desc",
      sizePerPageList: [10, 25, 50, 100],
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
        dataFormat: this.linkToTeam,
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
      <DataTable
        data={this.props.teams}
        columns={columns}
        pagination
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
