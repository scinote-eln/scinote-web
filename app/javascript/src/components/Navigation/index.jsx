import React, { Component } from "react";
import PropTypes from "prop-types";
import { connect } from "react-redux";
import { Navbar, Nav, NavItem } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import styled from "styled-components";
import {
  MAIN_COLOR_BLUE,
  WHITE_COLOR,
  BORDER_GRAY_COLOR
} from "../../config/constants/colors";

import TeamSwitch from "./components/TeamSwitch";
import GlobalActivitiesModal from "./components/GlobalActivitiesModal";
import SearchDropdown from "./components/SearchDropdown";
import NotificationsDropdown from "./components/NotificationsDropdown";
import InfoDropdown from "./components/InfoDropdown";
import UserAccountDropdown from "./components/UserAccountDropdown";
// Ignore so Heroku builds pass
//import withExtras from 'react-hijack';
//import addonsConfig from '../../componentLoader/config';
//import massageConfiguration from '../../componentLoader/massageConfiguration';
//import componentLoader from '../../componentLoader';

const StyledNavbar = styled(Navbar)`
  background-color: ${WHITE_COLOR};
  border-color: ${BORDER_GRAY_COLOR};
  margin-bottom: 0;
`;

const StyledBrand = styled.a`
  background-color: ${MAIN_COLOR_BLUE};

  &:hover,
  &:active,
  &:focus {
    background-color: ${MAIN_COLOR_BLUE} !important;
  }

  & > img {
    margin-top: -4px;
    max-width: 132px;
    max-height: 26px;
  }
`;

class Navigation extends Component {
  constructor(props) {
    super(props);
    this.state = {
      showActivitesModal: false,
      current_team: { id: 0 }
    };
    this.selectItemCallback = this.selectItemCallback.bind(this);
    this.closeModalCallback = this.closeModalCallback.bind(this);
  }

  selectItemCallback(key, ev) {
    switch (key) {
      case 1:
        window.location = "/";
        break;
      case 2:
        window.location = "/protocols";
        break;
      case 3:
        window.location = `/teams/${this.props.current_team.id}/repositories`;
        break;
      case 4:
        ev.preventDefault();
        this.setState({ showActivitesModal: !this.state.showActivitesModal });
        break;
      default:
    }
  }

  closeModalCallback() {
    this.setState({ showActivitesModal: false });
  }

  render() {
    return (
      <div id="mountPoint">
        <StyledNavbar onSelect={this.selectItemCallback}>
          <Navbar.Header>
            <Navbar.Brand>
              <StyledBrand href="/" title="SciNote">
                <img src="/images/logo.png" alt="Logo" />
              </StyledBrand>
            </Navbar.Brand>
          </Navbar.Header>
          <Nav>
            <NavItem eventKey={1}>
              <span className="fas fa-folder" title="Home" />&nbsp;
              <span className="visible-xs-inline visible-sm-inline">
                <FormattedMessage id="navbar.home_label" />
              </span>
            </NavItem>
            <NavItem eventKey={2}>
              <span
                className="fas fa-edit"
                title="Protocol repositories"
              />&nbsp;
              <span className="visible-xs-inline visible-sm-inline">
                <FormattedMessage id="navbar.protocols_label" />
              </span>
            </NavItem>
            <NavItem eventKey={3}>
              <i
                className="fas fa-list-alt"
                aria-hidden="true"
                title="Repositories"
              />&nbsp;
              <span className="visible-xs-inline visible-sm-inline">
                <FormattedMessage id="navbar.repositories_label" />
              </span>
            </NavItem>
            <NavItem eventKey={4}>
              <span
                className="fas fa-list"
                title="Activities"
              />&nbsp;
              <span className="visible-xs-inline visible-sm-inline">
                <FormattedMessage id="navbar.activities_label" />
              </span>
            </NavItem>
          </Nav>
          <Nav pullRight>
            <TeamSwitch eventKey={5} />
            <SearchDropdown />
            <NotificationsDropdown />
            <InfoDropdown />
            <UserAccountDropdown />
          </Nav>
        </StyledNavbar>
        <GlobalActivitiesModal
          showModal={this.state.showActivitesModal}
          onCloseModal={this.closeModalCallback}
        />
      </div>
    );
  }
}

Navigation.propTypes = {
  current_team: PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    current_team: PropTypes.bool.isRequired
  }).isRequired
};

// Map the states from store to component props
const mapStateToProps = ({ current_team }) => ({ current_team });

// Ignore so Heroku builds pass
//const NavigationWithExtras = withExtras({
//  identifier: 'navigation',
//  config: massageConfiguration(addonsConfig, 'navigation'),
//}, componentLoader)(Navigation);
//
//export default connect(mapStateToProps)(NavigationWithExtras);
export default connect(mapStateToProps)(Navigation);
