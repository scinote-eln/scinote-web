import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { FormattedMessage } from "react-intl";
import { NavDropdown, MenuItem, Glyphicon } from "react-bootstrap";
import styled from "styled-components";
import _ from "lodash";

import { BORDER_GRAY_COLOR } from "../../../app/constants/colors";
import { setCurrentUser, changeTeam } from "../../actions/TeamsActions";
import { getTeamsList } from "../../actions/TeamsActions";

const StyledNavDropdown = styled(NavDropdown)`
  border-left: 1px solid ${BORDER_GRAY_COLOR};
  border-right: 1px solid ${BORDER_GRAY_COLOR};
`;

class TeamSwitch extends Component {
  constructor(props) {
    super(props);
    this.displayTeams = this.displayTeams.bind(this);
  }

  componentDidMount() {
    this.props.getTeamsList();
  }

  changeTeam(teamId) {
    this.props.changeTeam(teamId);
  }

  displayTeams() {
    if (!_.isEmpty(this.props.all_teams)) {
      return this.props.all_teams.filter(team => !team.current_team).map(team =>
        <MenuItem onSelect={() => this.changeTeam(team.id)} key={team.id}>
          {team.name}
        </MenuItem>
      );
    }
  }

  newTeamLink() {
    return (
      <MenuItem href="/users/settings/teams/new" key="addNewTeam">
        <Glyphicon glyph="plus" />&nbsp;
        <FormattedMessage id="global_team_switch.new_team" />
      </MenuItem>
    );
  }

  render() {
    return (
      <StyledNavDropdown
        noCaret
        eventKey={this.props.eventKey}
        title={
          <span>
            <i className="fa fa-users" />&nbsp;{this.props.current_team.name}
          </span>
        }
        id="team-switch"
      >
        {this.displayTeams()}
        <MenuItem key="divider" divider />
        {this.newTeamLink()}
      </StyledNavDropdown>
    );
  }
}

TeamSwitch.propTypes = {
  getTeamsList: PropTypes.func.isRequired,
  eventKey: PropTypes.number.isRequired,
  changeTeam: PropTypes.func.isRequired,
  all_teams: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      current_team: PropTypes.bool.isRequired
    }).isRequired
  ),
  current_team: PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    current_team: PropTypes.bool.isRequired
  }).isRequired
};

// Map the states from store to component
const mapStateToProps = ({ all_teams, current_team }) => ({
  current_team,
  all_teams: _.values(all_teams)
});

// Map the fetch activity action to component
const mapDispatchToProps = dispatch => ({
  setCurrentUser() {
    dispatch(setCurrentUser());
  },
  changeTeam(teamId) {
    dispatch(changeTeam(teamId));
  },
  getTeamsList() {
    dispatch(getTeamsList());
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(TeamSwitch);
