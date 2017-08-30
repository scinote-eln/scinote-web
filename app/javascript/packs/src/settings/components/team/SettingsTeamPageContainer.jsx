import React, { Component } from "react";
import PropTypes, { number, string, bool } from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";
import axios from "../../../../app/axios";

import { TEAM_DETAILS_PATH } from "../../../../app/routes";
import {
  BORDER_LIGHT_COLOR,
  COLOR_CONCRETE
} from "../../../../app/constants/colors";

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

class SettingsTeamPageContainer extends Component {
  constructor(props) {
    super(props);
    this.state = {
      team: {},
      users: []
    };
  }

  componentDidMount() {
    const path = TEAM_DETAILS_PATH.replace(":team_id", this.props.params.id);
    axios.get(path).then(response => {

    });
  }

  render() {
    return (
      <Wrapper>
        <TabTitle>
          <FormattedMessage id="settings_page.all_teams" />
        </TabTitle>
      </Wrapper>
    );
  }
}

export default SettingsTeamPageContainer;
