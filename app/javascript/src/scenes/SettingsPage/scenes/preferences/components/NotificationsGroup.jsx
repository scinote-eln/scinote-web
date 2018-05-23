import React, { Component } from "react";
import { string, bool, func } from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import { updateUser } from "../../../../../services/api/users_api";
import NotificationsSwitch from "./NotificationsSwitch";
import {
  RECENT_NOTIFICATION,
  SYSTEM_NOTIFICATION,
  ASSIGNMENT_NOTIFICATION
} from "../../../../../config/constants/strings";
import { WHITE_COLOR } from "../../../../../config/constants/colors";
import avatarImg from "../../../../../assets/missing.png";

const Wrapper = styled.div`margin-bottom: 6px;`;

const IconWrapper = styled.div`
  margin-top: 12px;
  margin-left: 7px;
`;

const Icon = styled.span`
  border-radius: 50%;
  color: ${WHITE_COLOR};
  display: block;
  font-size: 15px;
  height: 30px;
  margin-right: 15px;
  padding: 7px;
  padding-bottom: 5px;
  padding-top: 5px;
  width: 30px;
`;

const Image = styled.span`
  border-radius: 50%;
  color: ${WHITE_COLOR};
  display: block;
  font-size: 15px;
  height: 30px;
  margin-right: 15px;
  width: 30px;
  overflow: hidden;
`;

class NotificationsGroup extends Component {
  constructor(props) {
    super(props);
    this.notificationImage = this.notificationImage.bind(this);
    this.inAppNotificationField = this.inAppNotificationField.bind(this);
    this.emailNotificationField = this.emailNotificationField.bind(this);
    this.updateStatus = this.updateStatus.bind(this);
    this.buttonGroupStatus = this.buttonGroupStatus.bind(this);
  }

  notificationImage() {
    if (this.props.type === RECENT_NOTIFICATION) {
      return (
        <Image>
          <img src={avatarImg} alt="default avatar" />
        </Image>
      );
    }
    return (
      <Icon style={{ backgroundColor: this.props.iconBackground }}>
        <i className={this.props.iconClasses} />
      </Icon>
    );
  }

  inAppNotificationField(value) {
    let params = {};
    switch (this.props.type) {
      case ASSIGNMENT_NOTIFICATION:
        params.assignments_notification = value;
        if(!value) {
          params.assignments_email_notification = false;
        }
        break;
      case RECENT_NOTIFICATION:
        params.recent_notification = value;
        if(!value) {
          params.recent_email_notification = false;
        }
        break;
      default:
        params = {}
    }
    return params
  }

  emailNotificationField() {
    switch (this.props.type) {
      case ASSIGNMENT_NOTIFICATION:
        return "assignments_email_notification";
      case RECENT_NOTIFICATION:
        return "recent_email_notification";
      case SYSTEM_NOTIFICATION:
        return "system_message_email_notification"
      default:
        return "";
    }
  }

  updateStatus(actionType, value) {
    if (actionType === "inAppNotification") {
      const params = this.inAppNotificationField(value);
      updateUser(params).then(() => this.props.reloadInfo());
    } else if (actionType === "emailNotification") {
      const emailField = this.emailNotificationField();
      updateUser({ [emailField]: value }).then(() => this.props.reloadInfo());
    }
  }

  // check if the in SciNote notification is disabled
  buttonGroupStatus() {
    return (
      this.props.type !== SYSTEM_NOTIFICATION && !this.props.inAppNotification
    );
  }

  render() {
    return (
      <Wrapper className="row">
        <IconWrapper className="col-sm-1">
          {this.notificationImage()}
        </IconWrapper>
        <div className="col-sm-10">
          <h5>
            <strong>
              <FormattedMessage id={this.props.title} />
            </strong>
          </h5>
          <p>
            <FormattedMessage id={this.props.subtitle} />
          </p>
          <div>
            <NotificationsSwitch
              title="settings_page.show_in_scinote"
              status={this.props.inAppNotification}
              updateStatus={value =>
                this.updateStatus("inAppNotification", value)}
              isDisabled={this.props.type === SYSTEM_NOTIFICATION}
            />
            <NotificationsSwitch
              title="settings_page.notify_me_via_email"
              status={this.props.emailNotification}
              updateStatus={value =>
                this.updateStatus("emailNotification", value)}
              isDisabled={false}
              isTemporarilyDisabled={this.buttonGroupStatus()}
            />
          </div>
        </div>
      </Wrapper>
    );
  }
}

NotificationsGroup.propTypes = {
  title: string.isRequired,
  subtitle: string.isRequired,
  type: string.isRequired,
  iconClasses: string,
  iconBackground: string,
  inAppNotification: bool,
  emailNotification: bool,
  reloadInfo: func.isRequired
};

NotificationsGroup.defaultProps = {
  iconClasses: "",
  iconBackground: "",
  emailNotification: false,
  inAppNotification: false
};

export default NotificationsGroup;
