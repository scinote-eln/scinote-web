import React, { Component } from "react";
import { Link } from "react-router-dom";
import { NavDropdown } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import styled from "styled-components";

import {
  getRecentNotifications,
  getUnreadNotificationsCount
} from "../../../services/api/notifications_api";
import {
  MAIN_COLOR_BLUE,
  WILD_SAND_COLOR,
  MYSTIC_COLOR
} from "../../../config/constants/colors";
import { SETTINGS_ACCOUNT_PREFERENCES } from "../../../config/routes";

import NotificationItem from "./NotificationItem";
import Spinner from "../../Spinner";
import CustomNavItem from "./CustomNavItem";

const StyledListHeader = styled(CustomNavItem)`
  background-color: ${MAIN_COLOR_BLUE};
  color: ${WILD_SAND_COLOR};
  font-weight: bold;
  padding: 8px;

  & a,
  a:hover,
  a:active {
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

const StyledSpan = styled.span`
  background-color: ${MAIN_COLOR_BLUE};
  border-radius: 5px;
  color: ${WILD_SAND_COLOR};
  font-size: 11px;
  font-weight: bold;
  margin-left: 12px;
  padding: 1px 6px;
  right: 19px;
  top: 3px;
  position: relative;
`;

class NotificationsDropdown extends Component {
  constructor(props) {
    super(props);
    this.state = {
      notifications: [],
      notificationsCount: 0
    };
    this.getRecentNotifications = this.getRecentNotifications.bind(this);
    this.renderNotifications = this.renderNotifications.bind(this);
    this.renderNotificationStatus = this.renderNotificationStatus.bind(this);
    this.loadStatus = this.loadStatus.bind(this);
    this.closeDropdown = this.closeDropdown.bind(this);
  }

  componentWillMount() {
    this.loadStatus();
  }

  componentDidMount() {
    const minutes = 120 * 1000;
    setInterval(this.loadStatus, minutes);
  }

  getRecentNotifications(e) {
    e.preventDefault();
    getRecentNotifications()
      .then(response =>
        this.setState({ notifications: response, notificationsCount: 0 })
      )
      .catch(error => {
        console.log("get Notifications Error: ", error); // TODO change this
      });
  }

  loadStatus() {
    getUnreadNotificationsCount().then(response => {
      this.setState({ notificationsCount: parseInt(response.count, 10) });
    });
  }

  closeDropdown() {
    this.dropdown.click();
  }

  renderNotifications() {
    const list = this.state.notifications.map(notification => (
      <NotificationItem key={notification.id} notification={notification} />
    ));

    const items =
      this.state.notifications.length > 0 ? (
        list
      ) : (
        <CustomNavItem>
          <Spinner />
        </CustomNavItem>
      );
    return items;
  }

  renderNotificationStatus() {
    if (this.state.notificationsCount > 0) {
      return <StyledSpan>{this.state.notificationsCount}</StyledSpan>;
    }
    return <span />;
  }

  render() {
    return (
      <StyledNavDropdown
        noCaret
        id="notifications-dropdown"
        title={
          <span
            ref={el => {
              this.dropdown = el;
            }}
          >
            <i className="fas fa-bell" />&nbsp;
            <span className="visible-xs-inline visible-sm-inline">
              <FormattedMessage id="navbar.notifications_label" />
            </span>
            {this.renderNotificationStatus()}
          </span>
        }
        onClick={this.getRecentNotifications}
      >
        <StyledListHeader>
          <span>
            <FormattedMessage id="notifications.dropdown_title" />
          </span>
          <span className="pull-right">
            <Link
              to={SETTINGS_ACCOUNT_PREFERENCES}
              onClick={this.closeDropdown}
            >
              <FormattedMessage id="notifications.dropdown_settings_link" />
            </Link>
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
