// @flow
import React, { Component } from "react";
import { FormattedMessage } from "react-intl";

import { getUserPreferencesInfo } from "../../../../services/api/users_api";
import PageTitle from "../../../../components/PageTitle";
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

type Props = {
  tabState: Function
}

type State = {
  timeZone: string,
  assignments_notification: boolean,
  assignments_email_notification: boolean,
  recent_notification: boolean,
  recent_email_notification: boolean,
  system_message_email_notification: boolean
}

class SettingsPreferences extends Component<Props, State> {
  constructor(props: Props) {
    super(props);

    this.state = {
      timeZone: "",
      assignments_notification: false,
      assignments_email_notification: false,
      recent_notification: false,
      recent_email_notification: false,
      system_message_email_notification: false
    };

    (this: any).getPreferencesInfo = this.getPreferencesInfo.bind(this);
  }

  componentDidMount(): void {
    this.getPreferencesInfo();
    this.props.tabState("1")
  }

  getPreferencesInfo(): void {
    getUserPreferencesInfo().then(data => {
      (this: any).setState(data);
    });
  }

  render() {
    return (
      <PageTitle localeID="page_title.settings_preference_page">
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
              iconClasses="fas fa-newspaper-o"
              inAppNotification={this.state.assignments_notification}
              emailNotification={this.state.assignments_email_notification}
              iconBackground={MAIN_COLOR_BLUE}
              reloadInfo={this.getPreferencesInfo}
            />
            <NotificationsGroup
              type={RECENT_NOTIFICATION}
              title="settings_page.recent_changes"
              subtitle="settings_page.recent_changes_msg"
              inAppNotification={this.state.recent_notification}
              emailNotification={this.state.recent_email_notification}
              reloadInfo={this.getPreferencesInfo}
            />
            <NotificationsGroup
              type={SYSTEM_NOTIFICATION}
              title="settings_page.system_message"
              subtitle="settings_page.system_message_msg"
              emailNotification={this.state.system_message_email_notification}
              iconClasses="fas fa-chess-rook"
              iconBackground={ICON_GREEN_COLOR}
              reloadInfo={this.getPreferencesInfo}
            />
          </div>
        </SettingsAccountWrapper>
      </PageTitle>
    );
  }
}

export default SettingsPreferences;
