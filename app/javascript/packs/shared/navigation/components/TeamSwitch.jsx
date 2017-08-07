import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { FormattedMessage } from "react-intl";
import { NavDropdown, MenuItem } from "react-bootstrap";

import { setCurrentUser, changeTeam } from "../../actions/TeamsActions";

class TeamSwitch extends Component {
  constructor(props) {
    super(props);
    this.displayTeams = this.displayTeams.bind(this);
  }

  changeTeam(teamId) {
    this.props.changeTeam(teamId);
  }

  displayTeams() {
    return this.props.all_teams.filter(team => !team.current_team).map(team =>
      <MenuItem onSelect={() => this.changeTeam(team.id)} key={team.id}>
        {team.name}
      </MenuItem>
    );
  }

  newTeamLink() {
    return (
      <MenuItem href="/users/settings/teams/new" key="addNewTeam">
        <span className="glyphicon glyphicon-plus" />
        <FormattedMessage id="global_team_switch.new_team" />
      </MenuItem>
    );
  }

  render() {
    return (
      <NavDropdown
        noCaret
        eventKey={this.props.eventKey}
        title={this.props.current_team.name}
        id="team-switch"
      >
        {this.displayTeams()}
        {this.newTeamLink()}
      </NavDropdown>
    );
  }
}

TeamSwitch.propTypes = {
  eventKey: PropTypes.number.isRequired,
  changeTeam: PropTypes.func.isRequired,
  all_teams: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      current_team: PropTypes.bool.isRequired
    })
  ),
  current_team: PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    current_team: PropTypes.bool.isRequired
  })
};

// Map the states from store to component
const mapStateToProps = ({ all_teams, current_team }) => {
  return { all_teams, current_team };
};

// Map the fetch activity action to component
const mapDispatchToProps = dispatch => ({
  setCurrentUser() {
    dispatch(setCurrentUser());
  },
  changeTeam(team_id) {
    dispatch(changeTeam(team_id));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(TeamSwitch);
