import React, { Component } from "react";
import { NavDropdown } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import axios from "axios";
import styled from "styled-components";

import { RECENT_NOTIFICATIONS_PATH } from "../../../config/routes";
import {
  MAIN_COLOR_BLUE,
  WILD_SAND_COLOR,
  MYSTIC_COLOR
} from "../../../config/constants/colors";

import NotificationItem from "./NotificationItem";
import Spinner from "../../Spinner";
import CustomNavItem from "./CustomNavItem";

const StyledListHeader = styled(CustomNavItem)`
  background-color: ${MAIN_COLOR_BLUE};
  color: ${WILD_SAND_COLOR};
  font-weight: bold;
  padding: 8px;

  & a, a:hover, a:active {
    color: ${WILD_SAND_COLOR};
  }
`;

const StyledListFooter = styled(CustomNavItem)`
  background-color: ${MYSTIC_COLOR};
  padding: 8px;
  text-align: center;
`;

const StyledNavDropdown = styled(NavDropdown)`
  & > .dropdown-menu {
    max-height: 500px;
    overflow-x: hidden;
    overflow-y: scroll;
    padding-bottom: 0;
    padding-top: 0;
    width: 450px;
    word-wrap: break-word;
  }
`;

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
      <StyledNavDropdown
        noCaret
        id="notifications-dropdown"
        title={
          <span>
            <i className="fa fa-bell" />&nbsp;
            <span className="visible-xs-inline visible-sm-inline">
              <FormattedMessage id="navbar.notifications_label" />
            </span>
          </span>
        }
        onClick={this.getRecentNotifications}
      >
        <StyledListHeader>
          <span>
            <FormattedMessage id="notifications.dropdown_title" />
          </span>
          <span className="pull-right">
            <a href="/users/settings/account/preferences">
              <FormattedMessage id="notifications.dropdown_settings_link" />
            </a>
          </span>
        </StyledListHeader>
        {this.renderNotifications()}
        <StyledListFooter>
          <a href="/users/notifications">
            <FormattedMessage id="notifications.dropdown_show_all" />
          </a>
        </StyledListFooter>
      </StyledNavDropdown>
    );
  }
}

export default NotificationsDropdown;
