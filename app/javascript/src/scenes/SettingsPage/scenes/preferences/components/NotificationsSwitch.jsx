import React, { Component } from "react";
import { string, bool, func } from "prop-types";
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
    this.state = { status: this.props.status };
    this.handleClick = this.handleClick.bind(this);
    this.disabledButton = this.disabledButton.bind(this);
  }

  handleClick(value) {
    if (!this.props.isDisabled) {
      this.props.updateStatus(value);
    }
  }

  disabledButton() {
    if(this.props.isTemporarilyDisabled) {
      return (
        <div className="btn-group">
          <LeftButton
            className="btn btn-danger"
            disabled
          >
            <FormattedMessage id="settings_page.no" />
          </LeftButton>
          <RightButton
            className="btn btn-default"
            disabled
          >
            <FormattedMessage id="settings_page.yes" />
          </RightButton>
        </div>
      );
    } else if(this.props.isDisabled) {
      return (
        <div className="btn-group">
          <LeftButton
            className="btn btn-default"
            disabled
          >
            <FormattedMessage id="settings_page.no" />
          </LeftButton>
          <RightButton
            className="btn btn-primary"
            disabled
          >
            <FormattedMessage id="settings_page.yes" />
          </RightButton>
        </div>
      );
    } else if(this.props.status) {
      return (
        <div className="btn-group">
          <LeftButton
            className="btn btn-default"
            onClick={() => this.handleClick(false)}
          >
            <FormattedMessage id="settings_page.no" />
          </LeftButton>
          <RightButton
            className="btn btn-primary"
            onClick={() => this.handleClick(true)}
          >
            <FormattedMessage id="settings_page.yes" />
          </RightButton>
        </div>
      );
    }
    return (
      <div className="btn-group">
        <LeftButton
          className="btn btn-danger"
          onClick={() => this.handleClick(false)}
        >
          <FormattedMessage id="settings_page.no" />
        </LeftButton>
        <RightButton
          className="btn btn-default"
          onClick={() => this.handleClick(true)}
        >
          <FormattedMessage id="settings_page.yes" />
        </RightButton>
      </div>
    );
  }
  render() {
    return (
      <Wrapper className="row">
        <div className="col-sm-4 col-sm-offset-1">
          <FormattedMessage id={this.props.title} />
        </div>
        <div className="col-sm-7">
          {this.disabledButton()}
        </div>
      </Wrapper>
    );
  }
}

NotificationsSwitch.propTypes = {
  title: string.isRequired,
  status: bool.isRequired,
  isDisabled: bool.isRequired,
  updateStatus: func.isRequired,
  isTemporarilyDisabled: bool
};

NotificationsSwitch.defaultProps = {
  isTemporarilyDisabled: false
}

export default NotificationsSwitch;
