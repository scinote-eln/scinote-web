// @flow
import React, { Component } from "react";
import { Route, Switch, Redirect } from "react-router-dom";
import { LinkContainer } from "react-router-bootstrap";
import { Nav, NavItem } from "react-bootstrap";
import { FormattedMessage } from "react-intl";

import {
  ROOT_PATH,
  SETTINGS_PATH,
  SETTINGS_TEAMS_ROUTE,
  SETTINGS_TEAM_ROUTE,
  SETTINGS_ACCOUNT_PROFILE,
  SETTINGS_ACCOUNT_PREFERENCES,
  SETTINGS_NEW_TEAM_ROUTE
} from "../../config/routes";

import PageTitle from "../../components/PageTitle";
import NotFound from "../../components/404/NotFound";
import SettingsProfile from "./scenes/profile";
import SettingsPreferences from "./scenes/preferences";
import SettingsTeams from "./scenes/teams";
import SettingsTeam from "./scenes/team";
import SettingsNewTeam from "./scenes/teams/new";

type State = {
  active: string,
  teamsTableSizePerPage: number
};

let componentMounted = false;

export default class SettingsPage extends Component<*, State> {
  constructor(props: *) {
    super(props);

    this.state = {
      active: "1",
      teamsTableSizePerPage: 10
    };
    (this: any).handleSelect = this.handleSelect.bind(this);
    (this: any).setTabState = this.setTabState.bind(this);
    (this: any).teamsTableOnSizePerPageList = this.teamsTableOnSizePerPageList.bind(this);
  }

  componentDidMount(): void {
    componentMounted = true;
  }

  componentWillUnmount(): void {
    componentMounted = false;
  }

  setTabState(tab: string): void {
    if (tab !== this.state.active && componentMounted) {
      (this: any).setState({ active: tab });
    }
  }

  teamsTableOnSizePerPageList(teamsTableSizePerPage: number): void {
    (this: any).setState({ teamsTableSizePerPage });
  }

  handleSelect(eventKey: string, event: SyntheticEvent<*>): void {
    event.preventDefault();
    (this: any).setState({ active: eventKey });
  }

  render() {
    return (
      <PageTitle localeID="page_title.root">
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
              to={SETTINGS_TEAMS_ROUTE}
              active={this.state.active === "2"}
            >
              <NavItem eventKey="2">
                <FormattedMessage id="settings_page.teams" />
              </NavItem>
            </LinkContainer>
          </Nav>
          <Switch>
            <Route exact path={ROOT_PATH} component={SettingsPreferences} />
            <Route
              exact
              path={SETTINGS_PATH}
              render={() => (
                <Redirect
                  to={SETTINGS_ACCOUNT_PROFILE}
                  component={SettingsPreferences}
                />
              )}
            />
            <Route
              path={SETTINGS_NEW_TEAM_ROUTE}
              component={props => (
                <SettingsNewTeam {...props} tabState={this.setTabState} />
              )}
            />
            <Route
              path={SETTINGS_TEAM_ROUTE}
              component={props => (
                <SettingsTeam {...props} tabState={this.setTabState} />
              )}
            />
            <Route
              path={SETTINGS_TEAMS_ROUTE}
              component={props => (
                <SettingsTeams
                  {...props}
                  tabState={this.setTabState}
                  sizePerPage={this.state.teamsTableSizePerPage}
                  onSizePerPageList={this.teamsTableOnSizePerPageList}
                />
              )}
            />
            <Route
              path={SETTINGS_ACCOUNT_PROFILE}
              component={props => (
                <SettingsProfile {...props} tabState={this.setTabState} />
              )}
            />
            <Route
              path={SETTINGS_ACCOUNT_PREFERENCES}
              component={props => (
                <SettingsPreferences {...props} tabState={this.setTabState} />
              )}
            />
            <Route component={NotFound} />
          </Switch>
        </div>
      </PageTitle>
    );
  }
}
