import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";

import InputDisabled from "./InputDisabled";
import InputTimezone from "./InputTimezone";
import { changeTimezone } from "../../../shared/actions/UsersActions";
import NotificationsGroup from "./NotificationsGroup";
import {
  ASSIGNMENT_NOTIFICATION,
  RECENT_NOTIFICATION,
  SYSTEM_NOTIFICATION
} from "./constants";

class SettingsPreferences extends Component {
  constructor(props) {
    super(props);

    this.state = {
      isTimeZoneEditable: false
    };
  }

  toggleIsEditable(fieldNameEnabled) {
    const editableState = this.state[fieldNameEnabled];
    this.setState({ [fieldNameEnabled]: !editableState });
  }

  render() {
    const isTimeZoneEditable = "isTimeZoneEditable";
    let timezoneField;

    if (this.state.isTimeZoneEditable) {
      timezoneField = (
        <InputTimezone
          labelValue="Time zone"
          inputValue={this.props.timezone}
          disableEdit={() => this.toggleIsEditable(isTimeZoneEditable)}
          saveData={timeZone => this.props.changeTimezone(timeZone)}
        />
      );
    } else {
      timezoneField = (
        <InputDisabled
          labelValue="Time zone"
          inputValue={this.props.timezone}
          inputType="text"
          enableEdit={() => this.toggleIsEditable(isTimeZoneEditable)}
        />
      );
    }

    return (
      <div className="col-xs-12 col-sm-7">
        {timezoneField}
        <small>
          Time zone setting affects all time & date fields throughout
          application.
        </small>

        <h3>Notifications</h3>
        <NotificationsGroup
          type={ASSIGNMENT_NOTIFICATION}
          title="Assignement"
          subtitle="Assignment notifications appear whenever you get assigned to a team, project, task."
          imageUrl={this.props.avatarPath}
        />
        <NotificationsGroup
          type={RECENT_NOTIFICATION}
          title="Recent changes"
          subtitle="Recent changes notifications appear whenever there is a change on a task you are assigned to."
          imageUrl={this.props.avatarPath}
        />
        <NotificationsGroup
          type={SYSTEM_NOTIFICATION}
          title="System message"
          subtitle="System message notifications are specifically sent by site maintainers to notify all users about a system update."
          imageUrl={this.props.avatarPath}
        />
      </div>
    );
  }
}

SettingsPreferences.propTypes = {
  timezone: PropTypes.string.isRequired,
  changeTimezone: PropTypes.func.isRequired,
  avatarPath: PropTypes.string.isRequired
};

const mapStateToProps = state => state.current_user;
const mapDispatchToProps = dispatch => ({
  changeTimezone(timezone) {
    dispatch(changeTimezone(timezone));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(
  SettingsPreferences
);
