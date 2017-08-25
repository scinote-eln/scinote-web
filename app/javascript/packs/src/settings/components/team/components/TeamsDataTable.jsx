import React, { Component } from "react";
import { connect } from "react-redux";
import { Button } from "react-bootstrap";
import { leaveTeamModalShow } from "../../../../../shared/actions/LeaveTeamActions";
import DataTable from "../../../../../shared/data_table";

class TeamsDataTable extends Component {
  constructor(props) {
    super(props);

    this.leaveTeamModal = this.leaveTeamModal.bind(this);
    this.leaveTeamButton = this.leaveTeamButton.bind(this);
  }

  leaveTeamModal(e, id) {
    const team = _.find(this.props.teams, el => el.id === id);
    this.props.leaveTeamModalShow(true, id, team.name);
  }

  leaveTeamButton(id) {
    return (
      <Button onClick={e => this.leaveTeamModal(e, id)}>Leave team</Button>
    );
  }

  render() {
    const columns = [
      { id: "name", name: "Name", isKey: false, textId: "name", position: 0 },
      { id: "role", name: "Role", isKey: false, textId: "role", position: 1 },
      {
        id: "members",
        name: "Members",
        isKey: false,
        textId: "members",
        position: 2
      },
      {
        id: "id",
        name: "",
        isKey: true,
        textId: "id",
        dataFormat: this.leaveTeamButton,
        position: 3
      }
    ];
    return <DataTable data={this.props.teams} columns={columns} />;
  }
}
//
// const mapDispatchToProps = dispatch => ({
//   leaveTeamModalShow(show, id) {
//     dispatch(leaveTeamModalShow(show, id));
//   }
// });

export default connect(null, { leaveTeamModalShow })(TeamsDataTable);
