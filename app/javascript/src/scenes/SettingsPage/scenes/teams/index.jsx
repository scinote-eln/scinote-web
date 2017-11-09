// @flow
import React, { Component } from "react";
import styled from "styled-components";
import { Breadcrumb } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import { getTeams } from "../../../../services/api/teams_api";
import { BORDER_LIGHT_COLOR } from "../../../../config/constants/colors";

import PageTitle from "../../../../components/PageTitle";
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

type Props = {
  tabState: Function,
  sizePerPage: number,
  onSizePerPageList: Function
};

type State = {
  teams: Array<Teams$Team>
};

class SettingsTeams extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      teams: [
        {
          id: 0,
          name: "",
          user_team_id: 0,
          role: "",
          members: 0,
          can_be_left: false
        }
      ]
    };
    (this: any).updateTeamsState = this.updateTeamsState.bind(this);
  }

  componentDidMount() {
    getTeams().then(response => {
      this.updateTeamsState(response);
    });
    // set team tab on active
    this.props.tabState("2");
  }

  updateTeamsState(teams: Array<Teams$Team>): void {
    this.setState({ teams });
  }

  render() {
    return (
      <PageTitle localeID="page_title.all_teams_page">
        <Wrapper>
          <Breadcrumb>
            <Breadcrumb.Item active>
              <FormattedMessage id="settings_page.all_teams" />
            </Breadcrumb.Item>
          </Breadcrumb>
          <TeamsPageDetails teams={this.state.teams} />
          <TeamsDataTable
            teams={this.state.teams}
            updateTeamsState={this.updateTeamsState}
            sizePerPage={this.props.sizePerPage}
            onSizePerPageList={this.props.onSizePerPageList}
          />
        </Wrapper>
      </PageTitle>
    );
  }
}

export default SettingsTeams;
