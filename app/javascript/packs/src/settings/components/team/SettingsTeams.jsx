import React from "react";
import PropTypes, { number, string, bool } from "prop-types";
import styled from "styled-components";
import { connect } from "react-redux";
import { FormattedMessage } from "react-intl";

import {
  BORDER_LIGHT_COLOR,
  COLOR_CONCRETE
} from "../../../../app/constants/colors";

import TeamsPageDetails from "./components/TeamsPageDetails";
import TeamsDataTable from "./components/TeamsDataTable";

const Wrapper = styled.div`
  background: white;
  box-sizing: border-box;
  border: 1px solid ${BORDER_LIGHT_COLOR};
  border-top: none;
  margin: 0;
  padding: 16px 15px 50px 15px;
`;

const TabTitle = styled.div`
  background-color: ${COLOR_CONCRETE};
  padding: 15px;
`;

const SettingsTeams = ({ teams }) =>
  <Wrapper>
    <TabTitle>
      <FormattedMessage id="settings_page.all_teams" />
    </TabTitle>
    <TeamsPageDetails teams={teams} />
    <TeamsDataTable teams={teams} />
  </Wrapper>;

SettingsTeams.propTypes = {
  teams: PropTypes.arrayOf(
    PropTypes.shape({
      id: number.isRequired,
      name: string.isRequired,
      current_team: bool.isRequired,
      role: string.isRequired,
      members: number.isRequired,
    }).isRequired
  )
};

SettingsTeams.defaultProps = {
  teams: [{id: 0, name: "", current_team: "", role: "", members: 0}]
};

const mapStateToProps = ({ all_teams }) => ({
  teams: all_teams.collection
});

export default connect(mapStateToProps)(SettingsTeams);
