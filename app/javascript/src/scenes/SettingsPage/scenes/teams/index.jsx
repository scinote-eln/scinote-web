// @flow

import React, { Component } from "react";
import styled from "styled-components";
import { Breadcrumb } from "react-bootstrap";
import { connect } from "react-redux";
import { FormattedMessage } from "react-intl";
import type { State } from "flow-typed";
import type { MapStateToProps } from "react-redux"

import { BORDER_LIGHT_COLOR } from "../../../../config/constants/colors";

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
  teams: Array<Team>
}

class SettingsTeams extends Component<Props> {
  static defaultProps = {
    teams: [{ id: 0, name: "", current_team: "", role: "", members: 0 }]
  }

  componentDidMount() {
    // set team tab on active
    this.props.tabState("2");
  }

  render() {
    const { teams } = this.props;
    return (
      <Wrapper>
        <Breadcrumb>
          <Breadcrumb.Item active>
            <FormattedMessage id="settings_page.all_teams" />
          </Breadcrumb.Item>
        </Breadcrumb>
        <TeamsPageDetails teams={teams} />
        <TeamsDataTable teams={teams} />
      </Wrapper>
    );
  }
}

const mapStateToProps: MapStateToProps<*, *, *> = (state: State) => ({
  teams: state.all_teams.collection
});

export default connect(mapStateToProps)(SettingsTeams);
