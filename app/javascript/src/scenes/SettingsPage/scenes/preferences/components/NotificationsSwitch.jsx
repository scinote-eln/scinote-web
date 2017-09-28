import React, { Component } from "react";
import { string, bool, func } from "prop-types";
import {
  ButtonToolbar,
  ToggleButtonGroup,
  ToggleButton
} from "react-bootstrap";
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
    if (this.props.isDisabled) {
      return (
        <ToggleButtonGroup
          type="radio"
          name={this.props.title}
          defaultValue={this.state.status}
          disabled
        >
          <ToggleButton disabled value={false}>
            No
          </ToggleButton>
          <ToggleButton disabled value={true}>
            Yes
          </ToggleButton>
        </ToggleButtonGroup>
      );
    }
    return (
      <ToggleButtonGroup
        type="radio"
        name={this.props.title}
        onChange={this.handleClick}
        defaultValue={this.state.status}
      >
        <ToggleButton value={false}>
          No
        </ToggleButton>
        <ToggleButton value={true}>
          Yes
        </ToggleButton>
      </ToggleButtonGroup>
    );
  }
  render() {
    return (
      <Wrapper className="row">
        <div className="col-sm-4 col-sm-offset-1">
          <FormattedMessage id={this.props.title} />
        </div>
        <div className="col-sm-7">
          <ButtonToolbar>{this.disabledButton()}</ButtonToolbar>
        </div>
      </Wrapper>
    );
  }
}

NotificationsSwitch.propTypes = {
  title: string.isRequired,
  status: bool.isRequired,
  isDisabled: bool.isRequired,
  updateStatus: func.isRequired
};

export default NotificationsSwitch;
