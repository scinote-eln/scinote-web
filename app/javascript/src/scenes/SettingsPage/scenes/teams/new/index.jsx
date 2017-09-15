import React from "react";
import styled from "styled-components";
import { Breadcrumb, FormGroup, FormControl, ControlLabel, HelpBlock, Button } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import { FormattedMessage } from "react-intl";
import { SETTINGS_TEAMS_ROUTE } from "../../../../../config/routes";

import { BORDER_LIGHT_COLOR } from "../../../../../config/constants/colors";

import NameFormControl from "./components/NameFormControl";

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
        <FormattedMessage id="settings_page.new_team.title" />
      </Breadcrumb.Item>
    </Breadcrumb>

    <form style={{ maxWidth: "500px" }}>

      <FormGroup controlId="formBasicText">
        <ControlLabel>
          <FormattedMessage id="settings_page.new_team.name_label" />
        </ControlLabel>
        <NameFormControl />
        <FormControl.Feedback />
        <HelpBlock>
          <FormattedMessage id="settings_page.new_team.name_sublabel" />
        </HelpBlock>
      </FormGroup>

      <FormGroup>
        <ControlLabel>
          <FormattedMessage id="settings_page.new_team.description_label" />
        </ControlLabel>
        <FormControl componentClass="textarea" />
        <FormControl.Feedback />
        <HelpBlock>
          <FormattedMessage id="settings_page.new_team.description_sublabel" />
        </HelpBlock>
      </FormGroup>

      <LinkContainer to={SETTINGS_TEAMS_ROUTE}>
        <Button>
          <FormattedMessage id="general.cancel" />
        </Button>
      </LinkContainer>
      <Button type="submit" className="btn-primary">
        <FormattedMessage id="settings_page.new_team.create" />
      </Button>
    </form>
  </Wrapper>;

export default SettingsNewTeam;