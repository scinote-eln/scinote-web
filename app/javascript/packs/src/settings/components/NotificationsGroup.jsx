import React, { Component } from "react";
import PropTypes from "prop-types";
import styled from "styled-components";

import NotificationsSwitchGroup from "./NotificationsSwitchGroup";

const Icon = styled.span`
  background-color: silver;
  border-radius: 50%;
  color: #f5f5f5;
  display: block !important;
  font-size: 15px;
  height: 30px;
  margin-right: 15px;
  padding: 7px;
  padding-bottom: 5px;
  padding-top: 5px;
  width: 30px;
`;

class NotificationsGroup extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <div>
        <div className="row">
          <div className="col-sm-2">
            <Icon>
              <i className="fa fa-newspaper-o" />
            </Icon>
          </div>
          <div className="col-sm-10">
            <h5>
              {this.props.title}
            </h5>
            <p>
              {this.props.subtitle}
            </p>
            <NotificationsSwitchGroup type={this.props.type} />
          </div>
        </div>
      </div>
    );
  }
}

NotificationsGroup.propTypes = {
  title: PropTypes.string.isRequired,
  subtitle: PropTypes.string.isRequired,
  type: PropTypes.string.isRequired
};

export default NotificationsGroup;
