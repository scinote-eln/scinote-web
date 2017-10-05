import React, { Component } from "react";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import { getStatisticsInfo } from "../../../../../services/api/users_api";
import MyStatisticsBox from "./MyStatisticsBox";

const Wrapper = styled.div`
  margin-left: -15px;
  width: 260px;
`;

class MyStatistics extends Component {
  constructor(props) {
    super(props);

    this.state = {
      stats: false,
      number_of_teams: 0,
      number_of_projects: 0,
      number_of_experiments: 0,
      number_of_protocols: 0
    };

    this.getStatisticsInfo = this.getStatisticsInfo.bind(this);
  }

  componentDidMount() {
    this.getStatisticsInfo();
  }

  getStatisticsInfo() {
    getStatisticsInfo()
      .then(response => {
        this.setState(Object.assign({}, response.statistics, { stats: true }));
      })
      .catch(error => {
        this.setState({ stats: false });
        console.log(error);
      });
  }

  renderStatBoxes() {
    if (this.state.stats) {
      return (
        <Wrapper>
          <MyStatisticsBox
            typeLength={this.state.number_of_teams}
            plural="settings_page.teams"
            singular="settings_page.team"
          />
          <MyStatisticsBox
            typeLength={this.state.number_of_projects}
            plural="settings_page.projects"
            singular="settings_page.project"
          />
          <MyStatisticsBox
            typeLength={this.state.number_of_experiments}
            plural="settings_page.experiments"
            singular="settings_page.experiment"
          />
          <MyStatisticsBox
            typeLength={this.state.number_of_protocols}
            plural="settings_page.protocols"
            singular="settings_page.protocol"
          />
        </Wrapper>
      );
    }

    return (
      <div>
        <FormattedMessage id="general.loading" />
      </div>
    );
  }

  render() {
    return (
      <div>
        <h2>
          <FormattedMessage id="settings_page.my_statistics" />
        </h2>
        {this.renderStatBoxes()}
      </div>
    );
  }
}

export default MyStatistics;
