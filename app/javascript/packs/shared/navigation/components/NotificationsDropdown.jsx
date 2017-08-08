import React, { Component } from "react";
import { NavDropdown } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import axios from "axios";

import { RECENT_NOTIFICATIONS_PATH } from "../../../app/routes";

import NotificationItem from "./NotificationItem";
import Spinner from "../../spinner";
import CustomNavItem from "./CustomNavItem";

class NotificationsDropdown extends Component {
  constructor(props) {
    super(props);
    this.state = { notifications: [] };
    this.getRecentNotifications = this.getRecentNotifications.bind(this);
    this.renderNotifications = this.renderNotifications.bind(this);
  }

  getRecentNotifications(e) {
    e.preventDefault();
    axios
      .get(RECENT_NOTIFICATIONS_PATH, { withCredentials: true })
      .then(({ data }) => {
        this.setState({ notifications: data });
      })
      .catch(error => {
        console.log("get Notifications Error: ", error); // TODO change this
      });
  }

  renderNotifications() {
    const list = this.state.notifications.map(notification =>
      <NotificationItem key={notification.id} notification={notification} />
    );

    const items =
      this.state.notifications.length > 0
        ? list
        : <CustomNavItem>
            <Spinner />
          </CustomNavItem>;
    return items;
  }

  render() {
    return (
      <NavDropdown
        noCaret
        id="notifications-dropdown"
        title={<i className="fa fa-bell" />}
        onClick={this.getRecentNotifications}
      >
        <CustomNavItem>
          <span>
            <FormattedMessage id="notifications.dropdown_title" />
          </span>
          <span className="pull-right">
            <a href="/users/settings/account/preferences">
              <FormattedMessage id="notifications.dropdown_settings_link" />
            </a>
          </span>
        </CustomNavItem>
        {this.renderNotifications()}
        <CustomNavItem>
          <a href="/users/notifications">
            <FormattedMessage id="notifications.dropdown_show_all" />
          </a>
        </CustomNavItem>
      </NavDropdown>
    );
  }
}

export default NotificationsDropdown;
