import React, { Component } from "react";
import PropTypes from "prop-types";
import { NavDropdown, MenuItem } from "react-bootstrap";

class TeamSwitch extends Component {
  constructor(props) {
    super(props);

    this.state = { currentTeam: { name: "" }, allTeams: [] };
  }

  render() {
    return (
      <NavDropdown
        eventKey={this.props.eventKey}
        title={this.state.currentTeam.name}
        id="team-switch"
      >
        <MenuItem eventKey={5.1}>Action</MenuItem>
      </NavDropdown>
    );
  }
}

TeamSwitch.propTypes = {
  eventKey: PropTypes.number.isRequired
}

export default TeamSwitch;
