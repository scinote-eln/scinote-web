import React from "react";
import { node, oneOfType, arrayOf } from "prop-types";
import { Nav, NavItem } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import { FormattedMessage } from "react-intl";
import styled from "styled-components";

import {
  BORDER_LIGHT_COLOR,
  SIDEBAR_HOVER_GRAY_COLOR,
  LIGHT_BLUE_COLOR
} from "../../../config/constants/colors";

import {
  SETTINGS_ACCOUNT_PREFERENCES,
  SETTINGS_ACCOUNT_PROFILE
} from "../../../config/routes";

const StyledLinkContainer = styled(LinkContainer)`
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

const Wrapper = styled.div`
  background: white;
  box-sizing: border-box;
  border: 1px solid ${BORDER_LIGHT_COLOR};
  border-top: none;
  margin: 0;
  padding: 16px 0 50px 0;
`;

const SettingsAccountWrapper = ({ children }) =>
  <Wrapper className="row">
    <div className="col-xs-12 col-sm-3">
      <Nav bsStyle="pills" stacked activeKey={1}>
        <StyledLinkContainer to={SETTINGS_ACCOUNT_PROFILE}>
          <NavItem>
            <FormattedMessage id="settings_page.profile" />
          </NavItem>
        </StyledLinkContainer>
        <StyledLinkContainer to={SETTINGS_ACCOUNT_PREFERENCES}>
          <NavItem>
            <FormattedMessage id="settings_page.preferences" />
          </NavItem>
        </StyledLinkContainer>
      </Nav>
    </div>
    {children}
  </Wrapper>;

SettingsAccountWrapper.propTypes = {
  children: oneOfType([arrayOf(node), node]).isRequired
};

export default SettingsAccountWrapper;
