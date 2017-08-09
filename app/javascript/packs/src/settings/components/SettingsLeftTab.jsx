import React, { Component } from "react";
import { Nav, NavItem } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";

class SettingsAccountLeftTab extends Component {
  constructor(props) {
    super(props);
    this.handleSelect = this.handleSelect.bind(this);
  }

  handleSelect(selectedKey) {}

  render() {
    return (
      <Nav bsStyle="pills" stacked activeKey={1} onSelect={this.handleSelect}>
        <LinkContainer to="/settings/account/profile">
          <NavItem eventKey={1}>Profile</NavItem>
        </LinkContainer>
        <LinkContainer to="/settings/account/preferences">
          <NavItem eventKey={2}>Preferences</NavItem>
        </LinkContainer>
      </Nav>
    );
  }
}

export default SettingsAccountLeftTab;
