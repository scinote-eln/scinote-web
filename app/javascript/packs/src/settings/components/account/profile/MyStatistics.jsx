import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import styled from "styled-components";

import MyStatisticsBox from "./MyStatisticsBox";

const Wrapper = styled.div`
  margin-left: -15px;
  width: 260px;
`;

class MyStatistics extends Component {
  render() {
    const stats = this.props.statistics;

    const statBoxes = () => {
      let boxes = <div>Loading...</div>;
      if (stats) {
        boxes = (
          <Wrapper>
            <MyStatisticsBox
              typeLength={stats.number_of_teams}
              typeText="Teams"
            />
            <MyStatisticsBox
              typeLength={stats.number_of_projects}
              typeText="Projects"
            />
            <MyStatisticsBox
              typeLength={stats.number_of_experiments}
              typeText="Experiments"
            />
            <MyStatisticsBox
              typeLength={stats.number_of_protocols}
              typeText="Protocols"
            />
          </Wrapper>
        );
      }

      return boxes;
    };

    return (
      <div>
        <h2>My Statistics</h2>

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
