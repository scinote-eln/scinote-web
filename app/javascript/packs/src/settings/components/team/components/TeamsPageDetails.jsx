import React from "react";
import PropTypes from "prop-types";
import styled from "styled-components"
import { FormattedMessage, FormattedPlural } from "react-intl";
import { Button } from "react-bootstrap";

const Wrapper = styled.div`
  margin: 15px 0;
`
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
      />
      <Button>New team</Button>
    </Wrapper>
  );
};

TeamsPageDetails.propTypes = {
  teams: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      current_team: PropTypes.bool.isRequired
    })
  )
};

TeamsPageDetails.defaultProps = {
  teams: []
};

export default TeamsPageDetails;
