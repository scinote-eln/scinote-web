import React, { Component } from "react";
import ReactRouterPropTypes from "react-router-prop-types";
import { Link } from "react-router-dom";
import styled from "styled-components";
import { Breadcrumb, Row, Col, Glyphicon, Well } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import { FormattedHTMLMessage, FormattedMessage } from "react-intl";
import moment from "moment";
import prettysize from "prettysize";
import axios from "../../../../config/axios";

import { SETTINGS_TEAMS_ROUTE } from "../../../../config/routes";
import { TEAM_DETAILS_PATH, SETTINGS_TEAMS } from "../../../../config/api_endpoints";
import { BORDER_LIGHT_COLOR } from "../../../../config/constants/colors";
import { SETTINGS_TEAMS_ROUTE } from "../../../../app/dom_routes";
import { TEAM_DETAILS_PATH } from "../../../../app/routes";

import TeamsMembers from "./components/TeamsMembers";
import UpdateTeamDescriptionModal from "./components/UpdateTeamDescriptionModal";
import UpdateTeamNameModal from "./components/UpdateTeamNameModal";

const Wrapper = styled.div`
  background: white;
  box-sizing: border-box;
  border: 1px solid ${BORDER_LIGHT_COLOR};
  border-top: none;
  margin: 0;
  padding: 16px 15px 50px 15px;
`;

const TabTitle = styled.div`padding: 15px;`;

const BadgeWrapper = styled.div`
  font-size: 1.4em;
  float: left;
  padding: 6px 10px;
  background-color: #37a0d9;
  color: #fff;
`;

const StyledWell = styled(Well)`
  padding: 9px;
  & > span {
    padding-left: 5px;
  }`;

const StyledDescriptionWell = styled(Well)`
  padding: 9px;
  & > span {
    padding-left: 5px;
  }
  &:hover {
    text-decoration: underline;
    cursor: pointer;
  }
`;

const StyledH3 = styled.h3`
  &:hover {
    text-decoration: underline;
    cursor: pointer;
  }
`;

const StyledOl = styled.ol`padding: 15px;`;

class SettingsTeam extends Component {
  constructor(props) {
    super(props);
    this.state = {
      showDescriptionModal: false,
      showNameModal: false,
      users: [],
      team: {
        id: 0,
        name: "",
        description: "",
        created_by: "",
        created_at: "",
        space_taken: 0
      }
    };
    this.showDescriptionModal = this.showDescriptionModal.bind(this);
    this.hideDescriptionModalCallback = this.hideDescriptionModalCallback.bind(
      this
    );
    this.updateTeamCallback = this.updateTeamCallback.bind(this);
    this.updateUsersCallback = this.updateUsersCallback.bind(this);
    this.showNameModal = this.showNameModal.bind(this);
    this.hideNameModalCallback = this.hideNameModalCallback.bind(this);
    this.renderEditNameModel = this.renderEditNameModel.bind(this);
  }

  componentDidMount() {
    const { id } = this.props.match.params;
    const path = TEAM_DETAILS_PATH.replace(":team_id", id);
    axios.get(path).then(response => {
      const { team, users } = response.data.team_details;
      this.setState({ users, team });
    });
  }

  showDescriptionModal() {
    this.setState({ showDescriptionModal: true });
  }

  hideDescriptionModalCallback() {
    this.setState({ showDescriptionModal: false });
  }

  showNameModal() {
    this.setState({ showNameModal: true });
  }

  hideNameModalCallback() {
    this.setState({ showNameModal: false });
  }

  updateTeamCallback(team) {
    this.setState({ team });
  }

  updateUsersCallback(users) {
    this.setState({ users });
  }

  renderDescription() {
    if (this.state.team.description) {
      return this.state.team.description;
    }
    return (
      <FormattedHTMLMessage id="settings_page.single_team.no_description" />
    );
  }

  renderEditNameModel() {
    if (this.state.showNameModal) {
      return(
        <UpdateTeamNameModal
          showModal={this.state.showNameModal}
          hideModal={this.hideNameModalCallback}
          team={this.state.team}
          updateTeamCallback={this.updateTeamCallback}
        />
      );
    }
  }

  render() {
    return (
      <Wrapper>
        <Breadcrumb>
          <LinkContainer to={SETTINGS_TEAMS_ROUTE}>
            <Breadcrumb.Item>
              <FormattedMessage id="settings_page.all_teams" />
            </Breadcrumb.Item>
          </LinkContainer>
          <Breadcrumb.Item active={true}>
            {this.state.team.name}
          </Breadcrumb.Item>
        </Breadcrumb>
        <TabTitle>
          <StyledH3 onClick={this.showNameModal}>
            {this.state.team.name}
          </StyledH3>
        </TabTitle>
        <Row>
          <Col xs={6} sm={3}>
            <BadgeWrapper>
              <Glyphicon glyph="calendar" />
            </BadgeWrapper>
            <StyledWell>
              <FormattedHTMLMessage
                id="settings_page.single_team.created_on"
                values={{
                  created_at: moment(this.state.team.created_at).format(
                    "DD.MM.YYYY"
                  )
                }}
              />
            </StyledWell>
          </Col>
          <Col xs={10} sm={5}>
            <BadgeWrapper>
              <Glyphicon glyph="user" />
            </BadgeWrapper>
            <StyledWell>
              <FormattedHTMLMessage
                id="settings_page.single_team.created_by"
                values={{ created_by: this.state.team.created_by }}
              />
            </StyledWell>
          </Col>
          <Col xs={8} sm={4}>
            <BadgeWrapper>
              <Glyphicon glyph="hdd" />
            </BadgeWrapper>
            <StyledWell>
              <FormattedHTMLMessage
                id="settings_page.single_team.space_usage"
                values={{
                  space_usage: prettysize(this.state.team.space_taken)
                }}
              />
            </StyledWell>
          </Col>
        </Row>
        <Row>
          <Col sm={12} onClick={this.showDescriptionModal}>
            <BadgeWrapper>
              <Glyphicon glyph="info-sign" />
            </BadgeWrapper>
            <StyledDescriptionWell>
              <span>
                {this.renderDescription()}
              </span>
            </StyledDescriptionWell>
          </Col>
        </Row>
        <TeamsMembers
          members={this.state.users}
          updateUsersCallback={this.updateUsersCallback}
          team={this.state.team}
        />
        <UpdateTeamDescriptionModal
          showModal={this.state.showDescriptionModal}
          hideModal={this.hideDescriptionModalCallback}
          team={this.state.team}
          updateTeamCallback={this.updateTeamCallback}
        />
        {this.renderEditNameModel()}
      </Wrapper>
    );
  }
}

SettingsTeam.PropTypes = {
  match: ReactRouterPropTypes.match.isRequired
};

export default SettingsTeam;
