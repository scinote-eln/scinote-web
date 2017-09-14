import React, { Component } from "react";
import styled from "styled-components";
import { Breadcrumb } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import { FormattedMessage } from "react-intl";
import { SETTINGS_TEAMS_ROUTE } from "../../../../../config/routes";

import { BORDER_LIGHT_COLOR } from "../../../../../config/constants/colors";

const Wrapper = styled.div`
  background: white;
  box-sizing: border-box;
  border: 1px solid ${BORDER_LIGHT_COLOR};
  border-top: none;
  margin: 0;
  padding: 16px 15px 50px 15px;
`;

const SettingsNewTeam = () =>
  <Wrapper>
    <Breadcrumb>
      <LinkContainer to={SETTINGS_TEAMS_ROUTE}>
        <Breadcrumb.Item>
          <FormattedMessage id="settings_page.all_teams" />
        </Breadcrumb.Item>
      </LinkContainer>
      <Breadcrumb.Item active={true}>
        <FormattedMessage id="settings_page.new_team" />
      </Breadcrumb.Item>
    </Breadcrumb>
    <span>TODO</span>
  </Wrapper>;

export default SettingsNewTeam;