import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import InputDisabled from "../../components/InputDisabled";
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

const WrapperInputDisabled = styled.div`
  margin: 20px 0;
  padding-bottom: 15px;
  border-bottom: 1px solid ${BORDER_LIGHT_COLOR};

  .settings-warning {
    margin-top: -5px;
  }
`;

class SettingsPreferences extends Component {
  constructor(props) {
    super(props);

    this.state = {
      isTimeZoneEditable: false,
      email: "",
      notifications: {
        assignmentsNotification: false,
        assignmentsNotificationEmail: false,
        recentNotification: false,
        recentNotificationEmail: false,
        systemMessageNofificationEmail: false
      }
    };

    this.setData = this.setData.bind(this);
  }

  componentDidMount() {
    this.getPreferencesInfo();
  }

  toggleIsEditable(fieldNameEnabled) {
    const editableState = this.state[fieldNameEnabled];
    this.setState({ [fieldNameEnabled]: !editableState });
  }

  setData({ data }) {
    const user = data.user;

    const newData = {
      timeZone: user.timeZone,
      notifications: {
        assignmentsNotification: user.notifications.assignmentsNotification,
        assignmentsNotificationEmail:
          user.notifications.assignmentsNotificationEmail,
        recentNotification: user.notifications.recentNotification,
        recentNotificationEmail: user.notifications.recentNotificationEmail,
        systemMessageNofificationEmail:
          user.notifications.systemMessageNofificationEmail
      }
    };

    this.setState(Object.assign({}, this.state, newData));
  }

  getPreferencesInfo() {
    // axios
    //   .get("/client_api/users/preferences_info")
    //   .then(response => this.setData(response))
    //   .catch(error => console.log(error));
  }

  render() {
    const isTimeZoneEditable = "isTimeZoneEditable";
    let timezoneField;

    if (this.state.isTimeZoneEditable) {
      timezoneField = (
        <InputTimezone
          labelValue="Time zone"
          inputValue={this.state.timeZone}
          disableEdit={() => this.toggleIsEditable(isTimeZoneEditable)}
          saveData={timeZone => this.props.changeTimezone(timeZone)}
        />
      );
    } else {
      timezoneField = (
        <WrapperInputDisabled>
          <InputDisabled
            labelTitle="settings_page.time_zone"
            inputValue={this.state.timeZone}
            inputType="text"
            enableEdit={() => this.toggleIsEditable(isTimeZoneEditable)}
          />
          <div className="settings-warning">
            <small>
              <FormattedMessage id="settings_page.time_zone_warning" />
            </small>
          </div>
        </WrapperInputDisabled>
      );
    }

    return (
      <SettingsAccountWrapper>
        <div className="col-xs-12 col-sm-9">
          {timezoneField}

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

SettingsPreferences.propTypes = {
  changeTimezone: PropTypes.func.isRequired,
  avatarPath: PropTypes.string.isRequired
};

const mapStateToProps = state => state.current_user;

export default connect(mapStateToProps)(SettingsPreferences);
