import React, { Component } from "react";
import PropTypes from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import {
  WHITE_COLOR,
  NOTIFICATION_YES,
  NOTIFICATION_YES_BORDER
} from "../../../../../config/constants/colors";

const Wrapper = styled.div`margin-top: 13px;`;

const LeftButton = styled.button`border-radius: 50px 0 0 50px;`;
const RightButton = styled.button`
  border-radius: 0 50px 50px 0;
  &.btn-primary {
    color: ${WHITE_COLOR};
    border-color: ${NOTIFICATION_YES_BORDER};
    background-color: ${NOTIFICATION_YES};
    &:hover {
      background-color: ${NOTIFICATION_YES_BORDER};
    }
  }
`;

class NotificationsSwitch extends Component {
  constructor(props) {
    super(props);

    this.handleClick = this.handleClick.bind(this);
  }

  handleClick() {
    if (!this.props.isDisabled) {
      this.props.toggleSwitch();
    }
  }

  render() {
    let switchBtn;

    if (this.props.isSwitchOn) {
      switchBtn = (
        <div className="btn-group">
          <LeftButton
            className="btn btn-default"
            disabled={this.props.isDisabled}
            onClick={this.handleClick}
          >
            <FormattedMessage id="settings_page.no" />
          </LeftButton>
          <RightButton
            className="btn btn-primary"
            disabled
            onClick={this.handleClick}
          >
            <FormattedMessage id="settings_page.yes" />
          </RightButton>
        </div>
      );
    } else {
      switchBtn = (
        <div className="btn-group">
          <LeftButton
            className="btn btn-danger"
            disabled
            onClick={this.handleClick}
          >
            <FormattedMessage id="settings_page.no" />
          </LeftButton>
          <RightButton
            className="btn btn-default"
            disabled={this.props.isDisabled}
            onClick={this.handleClick}
          >
            <FormattedMessage id="settings_page.yes" />
          </RightButton>
        </div>
      );
    }

    return (
      <Wrapper className="row">
        <div className="col-sm-4 col-sm-offset-1">
          <FormattedMessage id={this.props.title} />
        </div>
        <div className="col-sm-7">
          {switchBtn}
        </div>
      </Wrapper>
    );
  }
}

NotificationsSwitch.propTypes = {
  title: PropTypes.string.isRequired,
  isSwitchOn: PropTypes.bool.isRequired,
  isDisabled: PropTypes.bool.isRequired,
  toggleSwitch: PropTypes.func.isRequired
};

export default NotificationsSwitch;
