import React, { Component } from "react";
import { connect } from "react-redux";

import {
  changeAssignmentsNotification,
  changeAssignmentsNotificationEmail,
  changeRecentNotification,
  changeRecentNotificationEmail,
  changeSystemMessageNotificationEmail
} from "../../../shared/actions/UsersActions";

class NotificationsBtnGroup extends Component {
  constructor(props) {
    super(props);

    this.state = {
      isSciNoteSwitchOn: false,
      isEmailSwitchOn: false
    };
  }

  render() {
    return (
      <div>
        <h1>tonko</h1>
      </div>
    );
  }
}

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
  NotificationsBtnGroup
);
