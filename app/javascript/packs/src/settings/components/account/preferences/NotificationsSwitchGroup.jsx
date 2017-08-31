import React, { Component } from "react";
import { connect } from "react-redux";
import { string, bool, func } from "prop-types";

import NotificationsSwitch from "./NotificationsSwitch";

import {
  ASSIGNMENT_NOTIFICATION,
  RECENT_NOTIFICATION,
  SYSTEM_NOTIFICATION
} from "../constants";

import {
  changeAssignmentsNotification,
  changeAssignmentsNotificationEmail,
  changeRecentNotification,
  changeRecentNotificationEmail,
  changeSystemMessageNotificationEmail
} from "../../../../../shared/actions/UsersActions";

class NotificationsSwitchGroup extends Component {
  constructor(props) {
    super(props);

    this.state = {
      isSciNoteSwitchOn: false,
      isEmailSwitchOn: false
    };

    this.toggleFirstSwitch = this.toggleFirstSwitch.bind(this);
    this.toggleSecondSwitch = this.toggleSecondSwitch.bind(this);
    this.isSwitchDisabled = this.isSwitchDisabled.bind(this);
  }

  componentWillMount() {
    switch (this.props.type) {
      case ASSIGNMENT_NOTIFICATION:
        this.setState({
          isSciNoteSwitchOn: this.props.assignmentsNotification,
          isEmailSwitchOn: this.props.assignmentsNotificationEmail,
          sciNoteDispatch: state =>
            this.props.changeAssignmentsNotification(state),
          emailDispatch: state =>
            this.props.changeAssignmentsNotificationEmail(state)
        });
        break;
      case RECENT_NOTIFICATION:
        this.setState({
          isSciNoteSwitchOn: this.props.recentNotification,
          isEmailSwitchOn: this.props.recentNotificationEmail,
          sciNoteDispatch: state => this.props.changeRecentNotification(state),
          emailDispatch: state =>
            this.props.changeRecentNotificationEmail(state)
        });
        break;
      case SYSTEM_NOTIFICATION:
        this.setState({
          isSciNoteSwitchOn: true,
          isEmailSwitchOn: this.props.systemMessageNotificationEmail,
          sciNoteDispatch: state => `${state}: Do Nothing`,
          emailDispatch: state =>
            this.props.changeSystemMessageNotificationEmail(state)
        });
        break;
      default:
        this.setState({
          isSciNoteSwitchOn: false,
          isEmailSwitchOn: false
        });
    }
  }

  toggleFirstSwitch() {
    if (this.state.isSciNoteSwitchOn) {
      this.setState({ isSciNoteSwitchOn: false, isEmailSwitchOn: false });
      this.state.sciNoteDispatch(false);
      this.state.emailDispatch(false);
    } else {
      this.setState({ isSciNoteSwitchOn: true });
      this.state.sciNoteDispatch(true);
    }
  }

  toggleSecondSwitch() {
    if (this.state.isEmailSwitchOn) {
      this.setState({ isEmailSwitchOn: false });
      this.state.emailDispatch(false);
    } else {
      this.setState({ isEmailSwitchOn: true });
      this.state.emailDispatch(true);
    }
  }

  isSwitchDisabled() {
    if (this.props.type === SYSTEM_NOTIFICATION) {
      return true;
    }

    return false;
  }

  render() {
    return (
      <div>
        <NotificationsSwitch
          title="settings_page.show_in_scinote"
          isSwitchOn={this.state.isSciNoteSwitchOn}
          toggleSwitch={this.toggleFirstSwitch}
          isDisabled={this.isSwitchDisabled()}
        />
        <NotificationsSwitch
          title="settings_page.notify_me_via_email"
          isSwitchOn={this.state.isEmailSwitchOn}
          toggleSwitch={this.toggleSecondSwitch}
          isDisabled={!this.state.isSciNoteSwitchOn}
        />
      </div>
    );
  }
}

NotificationsSwitchGroup.propTypes = {
  type: string.isRequired,
  assignmentsNotification: bool.isRequired,
  assignmentsNotificationEmail: bool.isRequired,
  recentNotification: bool.isRequired,
  recentNotificationEmail: bool.isRequired,
  systemMessageNotificationEmail: bool.isRequired,
  changeAssignmentsNotification: func.isRequired,
  changeAssignmentsNotificationEmail: func.isRequired,
  changeRecentNotification: func.isRequired,
  changeRecentNotificationEmail: func.isRequired,
  changeSystemMessageNotificationEmail: func.isRequired
};

const mapStateToProps = state => state.current_user;
const mapDispatchToProps = dispatch => ({
  changeAssignmentsNotification(status) {
    dispatch(changeAssignmentsNotification(status));
  },
  changeAssignmentsNotificationEmail(status) {
    dispatch(changeAssignmentsNotificationEmail(status));
  },
  changeRecentNotification(status) {
    dispatch(changeRecentNotification(status));
  },
  changeRecentNotificationEmail(status) {
    dispatch(changeRecentNotificationEmail(status));
  },
  changeSystemMessageNotificationEmail(status) {
    dispatch(changeSystemMessageNotificationEmail(status));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(
  NotificationsSwitchGroup
);
