import React, { Component } from "react";
import { Nav, NavItem } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import styled from "styled-components";

import {
  SETTINGS_ACCOUNT_PROFILE,
  SETTINGS_ACCOUNT_PREFERENCES
} from "../../../app/routes";

import {
  MAIN_COLOR_BLUE,
  LIGHT_BLUE_COLOR
} from "../../../app/constants/colors";

const MyLinkContainer = styled(LinkContainer)`
  &.active {
    a {
      background-color: ${LIGHT_BLUE_COLOR} !important;
    }
  }
`;

class SettingsAccountLeftTab extends Component {
  constructor(props) {
    super(props);
    this.handleSelect = this.handleSelect.bind(this);
  }

  handleSelect(selectedKey) {}

  render() {
    return (
      <Nav bsStyle="pills" stacked activeKey={1} onSelect={this.handleSelect}>
        <MyLinkContainer to={SETTINGS_ACCOUNT_PROFILE}>
          <NavItem eventKey={1}>Profile</NavItem>
        </MyLinkContainer>
        <MyLinkContainer to={SETTINGS_ACCOUNT_PREFERENCES}>
          <NavItem eventKey={2}>Preferences</NavItem>
        </MyLinkContainer>
      </Nav>
    );
  }
}

export default SettingsAccountLeftTab;
