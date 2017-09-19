import React from "react";
import { Nav, NavItem } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import {
  SETTINGS_ACCOUNT_PROFILE,
  SETTINGS_ACCOUNT_PREFERENCES
} from "../../../../config/routes";

import {
  SIDEBAR_HOVER_GRAY_COLOR,
  LIGHT_BLUE_COLOR
} from "../../../../config/constants/colors";

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

export default () =>
  <Nav bsStyle="pills" stacked activeKey={1}>
    <MyLinkContainer to={SETTINGS_ACCOUNT_PROFILE}>
      <NavItem>
        <FormattedMessage id="settings_page.profile" />
      </NavItem>
    </MyLinkContainer>
    <MyLinkContainer to={SETTINGS_ACCOUNT_PREFERENCES}>
      <NavItem>
        <FormattedMessage id="settings_page.preferences" />
      </NavItem>
    </MyLinkContainer>
  </Nav>;
