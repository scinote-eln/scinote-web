import React, { Component } from "react";
import { Route, Switch, Redirect } from "react-router-dom";
import { LinkContainer } from "react-router-bootstrap";
import { Nav, NavItem } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import Navigation from "../../../shared/navigation";

import {
  SETTINGS_TEAMS_ROUTE,
  SETTINGS_TEAM_ROUTE
} from "../../../app/dom_routes";

import {
  ROOT_PATH,
  SETTINGS_PATH,
  SETTINGS_ACCOUNT_PATH,
  SETTINGS_TEAMS_PATH,
  SETTINGS_ACCOUNT_PROFILE,
  SETTINGS_TEAMS,
  SETTINGS_ACCOUNT_PROFILE_PATH
} from "../../../app/routes";

import NotFound from "../../../shared/404/NotFound";
import SettingsAccount from "./account/SettingsAccount";
import SettingsTeams from "./teams/SettingsTeams";
import SettingsTeamPageContainer from "./team/SettingsTeamPageContainer";

export default class MainNav extends Component {
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
        <Navigation page="Settings" />
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
              render={() => <Redirect to={SETTINGS_ACCOUNT_PROFILE_PATH} />}
            />
            <Route path={SETTINGS_ACCOUNT_PATH} component={SettingsAccount} />
            <Route path={SETTINGS_TEAMS_PATH} component={SettingsTeams} />
            <Route component={NotFound} />
          </Switch>
        </div>
      </div>
    );
  }
}
