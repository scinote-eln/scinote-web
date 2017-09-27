import React, { Component } from "react";
import { FormattedMessage } from "react-intl";
import { Button } from "react-bootstrap";
import styled from "styled-components";

import { getUserPreferencesInfo } from "../../../../services/api/users_api";
import SettingsAccountWrapper from "../../components/SettingsAccountWrapper";
import InputTimezone from "./components/InputTimezone";
import NotificationsGroup from "./components/NotificationsGroup";

import {
  ASSIGNMENT_NOTIFICATION,
  RECENT_NOTIFICATION,
  SYSTEM_NOTIFICATION
} from "../../../../config/constants/strings";

import {
  MAIN_COLOR_BLUE,
  ICON_GREEN_COLOR,
  BORDER_LIGHT_COLOR
} from "../../../../config/constants/colors";

const TutorialWrapper = styled.div`
  margin: 20px 0;
  padding-bottom: 15px;
  border-bottom: 1px solid ${BORDER_LIGHT_COLOR};
`
class SettingsPreferences extends Component {
  constructor(props) {
    super(props);

    this.state = {
      timeZone: "",
      assignmentsNotification: false,
      assignmentsEmailNotification: false,
      recentNotification: false,
      recentEmailNotification: false,
      systemMessageEmailNofification: false
    };

    this.getPreferencesInfo = this.getPreferencesInfo.bind(this)
  }

  componentDidMount() {
    this.getPreferencesInfo();
  }

  getPreferencesInfo() {
    getUserPreferencesInfo().then(data => {
      this.setState(data);
    });
  }

  render() {
    return (
      <SettingsAccountWrapper>
        <div className="col-xs-12 col-sm-9">
          <InputTimezone
            value={this.state.timeZone}
            loadPreferences={this.getPreferencesInfo}
          />
          <TutorialWrapper>
          <Button bsStyle="success">
            <FormattedMessage id="settings_page.repeat_tutorial" />
          </Button>
          </TutorialWrapper>
          <h3>Notifications</h3>
          <NotificationsGroup
            type={ASSIGNMENT_NOTIFICATION}
            title="settings_page.assignement"
            subtitle="settings_page.assignement_msg"
            imgUrl=""
            iconClasses="fa fa-newspaper-o"
            iconBackground={MAIN_COLOR_BLUE}
          />
          <NotificationsGroup
            type={RECENT_NOTIFICATION}
            title="settings_page.recent_changes"
            subtitle="settings_page.recent_changes_msg"
            imgUrl={this.props.avatarPath}
            iconClasses=""
            iconBackground=""
          />
          <NotificationsGroup
            type={SYSTEM_NOTIFICATION}
            title="settings_page.system_message"
            subtitle="settings_page.system_message_msg"
            imgUrl=""
            iconClasses="glyphicon glyphicon-tower"
            iconBackground={ICON_GREEN_COLOR}
          />
        </div>
      </SettingsAccountWrapper>
    );
  }
}

export default SettingsPreferences;
