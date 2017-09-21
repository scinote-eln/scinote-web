import React, { Component } from "react";
import { Route, Switch, Redirect } from "react-router-dom";
import { LinkContainer } from "react-router-bootstrap";
import { Nav, NavItem } from "react-bootstrap";
import { FormattedMessage } from "react-intl";

import {
  ROOT_PATH,
  SETTINGS_TEAMS_ROUTE,
  SETTINGS_TEAM_ROUTE,
  SETTINGS_ACCOUNT_PROFILE,
  SETTINGS_NEW_TEAM_ROUTE
} from "../../config/routes";

import {
  SETTINGS_PATH,
  SETTINGS_TEAMS,
  SETTINGS_ACCOUNT_PROFILE_PATH
} from "../../config/api_endpoints";

import NotFound from "../../components/404/NotFound";
import SettingsAccount from "./scenes/account/SettingsAccount";
import SettingsTeams from "./scenes/teams";
import SettingsTeam from "./scenes/team";
import SettingsNewTeam from "./scenes/teams/new";

export default class SettingsPage extends Component {
  constructor(props) {
    super(props);

    this.state = {
      active: "1"
    };
    this.handleSelect = this.handleSelect.bind(this);
  }

  handleSelect(eventKey) {
    event.preventDefault();
    this.setState({ active: eventKey });
  }

  render() {
    return (
      <div>
        <div className="container">
          <Nav bsStyle="tabs" activeKey="1" onSelect={this.handleSelect}>
            <LinkContainer
              active={this.state.active === "1"}
              to={SETTINGS_ACCOUNT_PROFILE}
            >
              <NavItem eventKey="1">
                <FormattedMessage id="settings_page.account" />
              </NavItem>
            </LinkContainer>
            <LinkContainer
              to={SETTINGS_TEAMS}
              active={this.state.active === "2"}
            >
              <NavItem eventKey="2">
                <FormattedMessage id="settings_page.team" />
              </NavItem>
            </LinkContainer>
          </Nav>
          <Switch>
            <Route exact path={ROOT_PATH} component={SettingsAccount} />
            <Route
              exact
              path={SETTINGS_PATH}
              render={() =>
                <Redirect
                  to={SETTINGS_ACCOUNT_PROFILE_PATH}
                  component={SettingsAccount}
                />}
            />
            <Route path={SETTINGS_NEW_TEAM_ROUTE} component={SettingsNewTeam} />
            <Route path={SETTINGS_TEAM_ROUTE} component={SettingsTeam} />
            <Route path={SETTINGS_TEAMS_ROUTE} component={SettingsTeams} />
            <Route
              to={SETTINGS_ACCOUNT_PROFILE_PATH}
              component={SettingsAccount}
            />
            <Route component={NotFound} />
          </Switch>
        </div>
      </div>
    );
  }
}
