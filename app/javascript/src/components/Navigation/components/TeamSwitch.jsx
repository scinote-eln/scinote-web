// @flow
import React, { Component } from "react";
import { connect } from "react-redux";
import { FormattedMessage } from "react-intl";
import { NavDropdown, MenuItem, Glyphicon } from "react-bootstrap";
import styled from "styled-components";
import _ from "lodash";

import { ROOT_PATH, SETTINGS_NEW_TEAM_ROUTE } from "../../../config/routes";
import { BORDER_GRAY_COLOR } from "../../../config/constants/colors";
import { getCurrentTeam, changeTeam } from "../../actions/TeamsActions";
import { getTeams } from "../../../services/api/teams_api";

const StyledNavDropdown = styled(NavDropdown)`
  border-left: 1px solid ${BORDER_GRAY_COLOR};
  border-right: 1px solid ${BORDER_GRAY_COLOR};
`;

type State = {
  allTeams: Array<Teams$Team>
}

type Props = {
  current_team: Teams$CurrentTeam,
  eventKey: string,
  getCurrentTeam: Function,
  changeTeam: Function
}

class TeamSwitch extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    (this: any).state = { allTeams: [] };
    (this: any).displayTeams = this.displayTeams.bind(this);
    (this: any).setTeams = this.setTeams.bind(this);
  }

  componentDidMount() {
    this.props.getCurrentTeam();
  }

  setTeams() {
    getTeams().then(response => (this: any).setState({ allTeams: response }));
  }

  changeTeam(teamId) {
    this.props.changeTeam(teamId);
    setTimeout(() => {
      window.location = ROOT_PATH;
    }, 1500);
  }

  displayTeams() {
    if (!_.isEmpty((this: any).state.allTeams)) {
      return (this: any).state.allTeams
        .filter(team => team.id !== this.props.current_team.id)
        .map(team => (
          <MenuItem onSelect={() => this.changeTeam(team.id)} key={team.id}>
            {team.name}
          </MenuItem>
        ));
    }
    return <MenuItem />;
  }

  newTeamLink() {
    return (
      <MenuItem href={SETTINGS_NEW_TEAM_ROUTE} key="addNewTeam">
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
        onClick={this.setTeams}
        title={
          <span>
            <i className="fas fa-users" />&nbsp;{this.props.current_team.name}
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

// Map the states from store to component
const mapStateToProps = ({ current_team }) => ({
  current_team
});

export default connect(mapStateToProps, { getCurrentTeam, changeTeam })(
  TeamSwitch
);
