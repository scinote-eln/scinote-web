import React, { Component } from "react";
import { connect } from "react-redux";
import { Navbar, Nav, NavItem } from "react-bootstrap";
import styled from "styled-components";
import { MAIN_COLOR_BLUE } from "../constants/colors";
import { getActivities } from "../actions/ActivitiesActions";
import TeamSwitch from "./components/TeamSwitch";
import GlobalActivitiesModal from "./components/GlobalActivitiesModal";

const StyledBrand = styled.a`
  background-color: ${MAIN_COLOR_BLUE};

  &:hover,
  &:active,
  &:focus {
    background-color: ${MAIN_COLOR_BLUE} !important;
  }

  & > img {
    height: 20px;
  }
`;

class Navigation extends Component {
  constructor(props) {
    super(props);
    this.state = {
      showActivitesModal: false,
      page: "",
      currentTeam: { id: 0 }
    };
    this.selectItemCallback = this.selectItemCallback.bind(this);
    this.closeModalCallback = this.closeModalCallback.bind(this);
  }

  selectItemCallback(key, ev) {
    if (key === 4) {
      ev.preventDefault();
      this.setState({ showActivitesModal: !this.state.showActivitesModal });
      // Call action creator to fetch activities from the server
      this.props.fetchActivities();
    }
  }

  closeModalCallback() {
    this.setState({ showActivitesModal: false });
  }

  render() {
    return (
      <div>
        <Navbar onSelect={this.selectItemCallback}>
          <Navbar.Header>
            <Navbar.Brand>
              <StyledBrand href="/" title="sciNote">
                <img src="/images/logo.png" alt="Logo" />
              </StyledBrand>
            </Navbar.Brand>
          </Navbar.Header>
          <Nav>
            <NavItem eventKey={1} href="/">
              <span className="glyphicon glyphicon-home" title="Home" />
            </NavItem>
            <NavItem eventKey={2} href="/protocols">
              <span
                className="glyphicon glyphicon-list-alt"
                title="Protocol repositories"
              />
            </NavItem>
            <NavItem
              eventKey={3}
              href={`/teams/${this.state.currentTeam.id}/repositories`}
            >
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
            <NavItem eventKey={6} href="#">
              Link Right
            </NavItem>
            <NavItem eventKey={7} href="#">
              Link Right
            </NavItem>
          </Nav>
        </Navbar>
        <GlobalActivitiesModal
          showModal={this.state.showActivitesModal}
          onCloseModal={this.closeModalCallback}
        />
      </div>
    );
  }
}

// Map the fetch activity action to component
const mapDispatchToProps = dispatch => ({
  fetchActivities() {
    dispatch(getActivities());
  }
});

export default connect(null, mapDispatchToProps)(Navigation);
