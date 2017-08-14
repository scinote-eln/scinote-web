import React, { Component } from "react";
import { Nav, NavItem } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";

import {
  SETTINGS_ACCOUNT_PROFILE,
  SETTINGS_ACCOUNT_PREFERENCES
} from "../../../app/routes";

class SettingsAccountLeftTab extends Component {
  constructor(props) {
    super(props);
    this.handleSelect = this.handleSelect.bind(this);
  }

  handleSelect(selectedKey) {}

  render() {
    return (
      <Nav bsStyle="pills" stacked activeKey={1} onSelect={this.handleSelect}>
        <LinkContainer to={SETTINGS_ACCOUNT_PROFILE}>
          <NavItem eventKey={1}>Profile</NavItem>
        </LinkContainer>
        <LinkContainer to={SETTINGS_ACCOUNT_PREFERENCES}>
          <NavItem eventKey={2}>Preferences</NavItem>
        </LinkContainer>
      </Nav>
    );
  }
}

export default SettingsAccountLeftTab;
