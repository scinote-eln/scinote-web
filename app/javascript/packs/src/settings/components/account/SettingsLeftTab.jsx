import React, { Component } from "react";
import { Nav, NavItem } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import styled from "styled-components";

import {
  SETTINGS_ACCOUNT_PROFILE,
  SETTINGS_ACCOUNT_PREFERENCES
} from "../../../../app/routes";

import {
  SIDEBAR_HOVER_GRAY_COLOR,
  LIGHT_BLUE_COLOR
} from "../../../../app/constants/colors";

const MyLinkContainer = styled(LinkContainer)`
  a {
    color: ${LIGHT_BLUE_COLOR};
    padding-left: 0;
  }
  &.active > a:after {
    content: '';
    position: absolute;
    left: 100%;
    top: 50%;
    margin-top: -19px;
    border-top: 19px solid transparent;
    border-left: 13px solid ${LIGHT_BLUE_COLOR};
    border-bottom: 19px solid transparent;
  }

  a:hover {
    background-color: ${SIDEBAR_HOVER_GRAY_COLOR} !important;
  }
  
  &.active {
    a {
      background-color: ${LIGHT_BLUE_COLOR} !important;
      border-radius: 3px 0 0 3px;
      border-left: 13px solid ${LIGHT_BLUE_COLOR};
      border-radius: 3px 0 0 3px;
    }
  }
`;

const SettingsLeftTab = () =>
  <Nav bsStyle="pills" stacked activeKey={1}>
    <MyLinkContainer to={SETTINGS_ACCOUNT_PROFILE}>
      <NavItem eventKey={1}>Profile</NavItem>
    </MyLinkContainer>
    <MyLinkContainer to={SETTINGS_ACCOUNT_PREFERENCES}>
      <NavItem eventKey={2}>Preferences</NavItem>
    </MyLinkContainer>
  </Nav>;

export default SettingsLeftTab;
