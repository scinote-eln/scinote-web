import React, { Component } from "react";
import PropTypes from "prop-types";
import { connect } from "react-redux";
import { Navbar, Nav, NavItem } from "react-bootstrap";
import styled from "styled-components";
import {
  MAIN_COLOR_BLUE,
  WHITE_COLOR,
  BORDER_GRAY_COLOR
} from "../../app/constants/colors";
import { getActivities, destroyActivities } from "../actions/ActivitiesActions";
import TeamSwitch from "./components/TeamSwitch";
import GlobalActivitiesModal from "./components/GlobalActivitiesModal";
import SearchDropdown from "./components/SearchDropdown";
import NotificationsDropdown from "./components/NotificationsDropdown";
import InfoDropdown from "./components/InfoDropdown";
import UserAccountDropdown from "./components/UserAccountDropdown";

const StyledNavbar = styled(Navbar)`
  background-color: ${WHITE_COLOR};
  border-color: ${BORDER_GRAY_COLOR};
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
      page: "",
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
        // Call action creator to fetch activities from the server
        this.props.fetchActivities();
        break;
      default:
    }
  }

  closeModalCallback() {
    this.setState({ showActivitesModal: false });
    this.props.destroyActivities();
  }

  render() {
    return (
      <div>
        <StyledNavbar onSelect={this.selectItemCallback}>
          <Navbar.Header>
            <Navbar.Brand>
              <StyledBrand href="/" title="sciNote">
                <img src="/images/logo.png" alt="Logo" />
              </StyledBrand>
            </Navbar.Brand>
          </Navbar.Header>
          <Nav>
            <NavItem eventKey={1}>
              <span className="glyphicon glyphicon-home" title="Home" />
            </NavItem>
            <NavItem eventKey={2}>
              <span
                className="glyphicon glyphicon-list-alt"
                title="Protocol repositories"
              />
            </NavItem>
            <NavItem eventKey={3}>
              <i
                className="fa fa-cubes"
                aria-hidden="true"
                title="Repositories"
              />
            </NavItem>
            <NavItem eventKey={4}>
              <span
                className="glyphicon glyphicon-equalizer"
                title="Activities"
              />
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
  fetchActivities: PropTypes.func.isRequired,
  destroyActivities: PropTypes.func.isRequired,
  current_team: PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    current_team: PropTypes.bool.isRequired
  }).isRequired
};

// Map the states from store to component props
const mapStateToProps = ({ current_team }) => ({ current_team });

// Map the fetch activity action to component props
const mapDispatchToProps = dispatch => ({
  fetchActivities() {
    dispatch(getActivities());
  },
  destroyActivities() {
    dispatch(destroyActivities());
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(Navigation);
