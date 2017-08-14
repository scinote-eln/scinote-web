import React, { Component } from "react";
import { LinkContainer } from "react-router-bootstrap";
import { Nav, NavItem } from "react-bootstrap";

import { SETTINGS_ACCOUNT_PROFILE, SETTINGS_TEAMS } from "../../../app/routes";

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
        <Nav bsStyle="tabs" activeKey="1" onSelect={this.handleSelect}>
          <LinkContainer
            active={this.state.active === "1"}
            to={SETTINGS_ACCOUNT_PROFILE}
          >
            <NavItem eventKey="1">Account</NavItem>
          </LinkContainer>
          <LinkContainer to={SETTINGS_TEAMS} active={this.state.active === "2"}>
            <NavItem eventKey="2">Team</NavItem>
          </LinkContainer>
        </Nav>
      </div>
    );
  }
}
