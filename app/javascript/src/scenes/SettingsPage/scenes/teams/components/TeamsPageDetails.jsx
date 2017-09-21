import React from "react";
import { LinkContainer } from "react-router-bootstrap";
import PropTypes, { number, string, bool } from "prop-types";
import styled from "styled-components";
import { FormattedMessage, FormattedPlural } from "react-intl";
import { Button, Glyphicon } from "react-bootstrap";
import { SETTINGS_NEW_TEAM_ROUTE } from "../../../../../config/routes";

const Wrapper = styled.div`margin: 15px 0;`;
const TeamsPageDetails = ({ teams }) => {
  const teamsNumber = teams.length;
  return (
    <Wrapper>
      <FormattedPlural
        value={teamsNumber}
        one={
          <FormattedMessage
            id="settings_page.in_team"
            values={{
              num: teamsNumber
            }}
          />
        }
        other={
          <FormattedMessage
            id="settings_page.in_teams"
            values={{
              num: teamsNumber
            }}
          />
        }
      />&nbsp;
      <LinkContainer to={SETTINGS_NEW_TEAM_ROUTE}>
        <Button>
          <Glyphicon glyph="plus" />&nbsp;<FormattedMessage id="global_team_switch.new_team" />
        </Button>
      </LinkContainer>
    </Wrapper>
  );
};

TeamsPageDetails.propTypes = {
  teams: PropTypes.arrayOf(
    PropTypes.shape({
      id: number.isRequired,
      name: string.isRequired,
      current_team: bool.isRequired,
      role: string.isRequired,
      members: number.isRequired,
      can_be_leaved: bool.isRequired
    })
  )
};

TeamsPageDetails.defaultProps = {
  teams: []
};

export default TeamsPageDetails;
