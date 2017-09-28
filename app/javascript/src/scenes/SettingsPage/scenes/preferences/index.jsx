import React, { Component } from "react";
import { FormattedMessage } from "react-intl";

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
  ICON_GREEN_COLOR
} from "../../../../config/constants/colors";

class SettingsPreferences extends Component {
  constructor(props) {
    super(props);

    this.state = {
      timeZone: "",
      assignmentsNotification: false,
      assignmentsEmailNotification: false,
      recentNotification: false,
      recentEmailNotification: false,
      systemMessageEmailNotification: false
    };

    this.getPreferencesInfo = this.getPreferencesInfo.bind(this);
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
          <h3>
            <FormattedMessage id="settings_page.notifications" />
          </h3>
          <NotificationsGroup
            type={ASSIGNMENT_NOTIFICATION}
            title="settings_page.assignement"
            subtitle="settings_page.assignement_msg"
            iconClasses="fa fa-newspaper-o"
            inAppNotification={this.state.assignmentsNotification}
            emailNotification={
              this.state.assignmentsEmailNotification
            }
            iconBackground={MAIN_COLOR_BLUE}
            reloadInfo={this.getPreferencesInfo}
          />
          <NotificationsGroup
            type={RECENT_NOTIFICATION}
            title="settings_page.recent_changes"
            subtitle="settings_page.recent_changes_msg"
            inAppNotification={this.state.recentNotification}
            emailNotification={this.state.recentEmailNotification}
            reloadInfo={this.getPreferencesInfo}
          />
          <NotificationsGroup
            type={SYSTEM_NOTIFICATION}
            title="settings_page.system_message"
            subtitle="settings_page.system_message_msg"
            emailNotification={
              this.state.systemMessageEmailNotification
            }
            iconClasses="glyphicon glyphicon-tower"
            iconBackground={ICON_GREEN_COLOR}
            reloadInfo={this.getPreferencesInfo}
          />
        </div>
      </SettingsAccountWrapper>
    );
  }
}

export default SettingsPreferences;
