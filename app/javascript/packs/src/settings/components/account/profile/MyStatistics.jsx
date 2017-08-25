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
  render() {
    const stats = this.props.statistics;

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
              typeLength={stats.number_of_teams}
              plural="settings_page.teams"
              singular="settings_page.team"
            />
            <MyStatisticsBox
              typeLength={stats.number_of_projects}
              plural="settings_page.projects"
              singular="settings_page.project"
            />
            <MyStatisticsBox
              typeLength={stats.number_of_experiments}
              plural="settings_page.experiments"
              singular="settings_page.experiment"
            />
            <MyStatisticsBox
              typeLength={stats.number_of_protocols}
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

MyStatistics.defaultProps = {
  statistics: null
};

MyStatistics.propTypes = {
  statistics: PropTypes.shape({
    number_of_teams: PropTypes.number.isRequired,
    number_of_projects: PropTypes.number.isRequired,
    number_of_experiments: PropTypes.number.isRequired,
    number_of_protocols: PropTypes.number.isRequired
  })
};

const mapStateToProps = state => state.current_user;

export default connect(mapStateToProps, {})(MyStatistics);
