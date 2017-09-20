import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import MyStatisticsBox from "./MyStatisticsBox";

const Wrapper = styled.div`
  margin-left: -15px;
  width: 260px;
`;

class MyStatistics extends Component {
  constructor(props) {
    super(props);

    this.state = {
      statistics: {
        teamSum: 0,
        projectsSum: 0,
        experimentsSum: 0,
        protocolsSum: 0
      }
    };

    this.setData = this.setData.bind(this);
  }

  componentDidMount() {
    this.getStatisticsInfo();
  }

  setData({ data }) {
    const user = data.user;

    const newData = {
      statistics: {
        teamsSum: user.statistics.number_of_teams,
        projectsSum: user.statistics.number_of_projects,
        experimentsSum: user.statistics.number_of_experiments,
        protocolsSum: user.statistics.number_of_protocols
      }
    };

    this.setState(Object.assign({}, this.state, newData));
  }

  getStatisticsInfo() {
    // axios
    //   .get("/client_api/users/statistics_info")
    //   .then(response => this.setData(response))
    //   .catch(error => console.log(error));
  }

  render() {
    const stats = this.state.statistics;

    const statBoxes = () => {
      let boxes = (
        <div>
          <FormattedMessage id="general.loading" />
        </div>
      );
      if (stats) {
        boxes = (
          <Wrapper>
            <MyStatisticsBox
              typeLength={stats.teamsSum}
              plural="settings_page.teams"
              singular="settings_page.team"
            />
            <MyStatisticsBox
              typeLength={stats.projectsSum}
              plural="settings_page.projects"
              singular="settings_page.project"
            />
            <MyStatisticsBox
              typeLength={stats.experimentsSum}
              plural="settings_page.experiments"
              singular="settings_page.experiment"
            />
            <MyStatisticsBox
              typeLength={stats.protocolsSum}
              plural="settings_page.protocols"
              singular="settings_page.protocol"
            />
          </Wrapper>
        );
      }

      return boxes;
    };

    return (
      <div>
        <h2>
          <FormattedMessage id="settings_page.my_statistics" />
        </h2>

        {statBoxes()}
      </div>
    );
  }
}

MyStatistics.propTypes = {
  statistics: PropTypes.shape({
    teamsSum: PropTypes.number.isRequired,
    projectsSum: PropTypes.number.isRequired,
    experimentsSum: PropTypes.number.isRequired,
    protocolsSum: PropTypes.number.isRequired
  })
};

const mapStateToProps = state => state.current_user;

export default connect(mapStateToProps, {})(MyStatistics);
