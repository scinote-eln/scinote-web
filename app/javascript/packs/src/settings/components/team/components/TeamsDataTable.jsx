import React, { Component } from "react";
import { TableHeaderColumn } from "react-bootstrap-table";
import { connect } from "react-redux";
import { Button } from "react-bootstrap";
import { leaveTeamModalShow } from "../../../../../shared/actions/LeaveTeamActions";
import DataTable from "../../../../../shared/data_table";

class TeamsDataTable extends Component {
  constructor(props) {
    super(props);
    this.leaveTeamModal = this.leaveTeamModal.bind(this);
  }

  leaveTeamModal(e, id) {
    e.peventDefault();
    this.props.leaveTeamModalShow(true, id);
  }

  leaveTeamButton(id) {
    return (
      <Button onClick={e => this.leaveTeamModal(e, id)}>Leave team</Button>
    );
  }

  render() {
    return (
      <DataTable data={this.props.teams}>
        <TableHeaderColumn isKey dataField="name">
          Name
        </TableHeaderColumn>
        <TableHeaderColumn dataField="role">Role</TableHeaderColumn>
        <TableHeaderColumn dataField="members">Memebers</TableHeaderColumn>
        <TableHeaderColumn dataField="id" dataFormat={this.leaveTeamButton} />
      </DataTable>
    );
  }
}

const mapDispatchToProps = dispatch => ({
  leaveTeamModalShow(show, id) {
    dispatch(leaveTeamModalShow(show, id));
  }
});

export default connect(null, mapDispatchToProps)(TeamsDataTable);
