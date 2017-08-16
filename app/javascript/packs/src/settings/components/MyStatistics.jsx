import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";

import MyStatisticsBox from "./MyStatisticsBox";

class MyStatistics extends Component {
  render() {
    const stats = this.props.statistics;

    const statBoxes = () => {
      let boxes = <div>Loading...</div>;
      if (stats) {
        boxes = (
          <div>
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
          </div>
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
