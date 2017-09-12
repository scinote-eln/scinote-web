import React, { Component } from "react";
import ReactRouterPropTypes from "react-router-prop-types";
import styled from "styled-components";
import { Row, Col, Glyphicon, Well } from "react-bootstrap";
import { FormattedHTMLMessage, FormattedMessage } from "react-intl";
import moment from "moment";
import prettysize from "prettysize";
import axios from "../../../../app/axios";

import { TEAM_DETAILS_PATH } from "../../../../app/routes";
import {
  BORDER_LIGHT_COLOR,
  COLOR_CONCRETE
} from "../../../../app/constants/colors";

import TeamsMembers from "./components/TeamsMembers";
import UpdateTeamDescriptionModal from "./components/UpdateTeamDescriptionModal";

const Wrapper = styled.div`
  background: white;
  box-sizing: border-box;
  border: 1px solid ${BORDER_LIGHT_COLOR};
  border-top: none;
  margin: 0;
  padding: 16px 15px 50px 15px;
`;

const TabTitle = styled.div`
  background-color: ${COLOR_CONCRETE};
  padding: 15px;
`;

const BadgeWrapper = styled.div`
  font-size: 1.4em;
  float: left;
  padding: 6px 10px;
  background-color: #37a0d9;
  color: #fff;
`;

const StyledWell = styled(Well)`
  &:hover {
    text-decoration: underline;
    cursor: pointer;
  }
`;

class SettingsTeamPageContainer extends Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
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
    this.setState({ showModal: true });
  }

  hideDescriptionModalCallback() {
    this.setState({ showModal: false });
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

  render() {
    return (
      <Wrapper>
        <TabTitle>
          <FormattedMessage id="settings_page.all_teams" />
          {` / ${this.state.team.name}`}
        </TabTitle>
        <Row>
          <Col xs={6} sm={3}>
            <BadgeWrapper>
              <Glyphicon glyph="calendar" />
            </BadgeWrapper>
            <Well>
              <FormattedHTMLMessage
                id="settings_page.single_team.created_on"
                values={{
                  created_at: moment(this.state.team.created_at).format(
                    "DD.MM.YYYY"
                  )
                }}
              />
            </Well>
          </Col>
          <Col xs={10} sm={5}>
            <BadgeWrapper>
              <Glyphicon glyph="user" />
            </BadgeWrapper>
            <Well>
              <FormattedHTMLMessage
                id="settings_page.single_team.created_by"
                values={{ created_by: this.state.team.created_by }}
              />
            </Well>
          </Col>
          <Col xs={8} sm={4}>
            <BadgeWrapper>
              <Glyphicon glyph="hdd" />
            </BadgeWrapper>
            <Well>
              <FormattedHTMLMessage
                id="settings_page.single_team.space_usage"
                values={{
                  space_usage: prettysize(this.state.team.space_taken)
                }}
              />
            </Well>
          </Col>
        </Row>
        <Row>
          <Col sm={12} onClick={this.showDescriptionModal}>
            <BadgeWrapper>
              <Glyphicon glyph="info-sign" />
            </BadgeWrapper>
            <StyledWell>
              {this.renderDescription()}
            </StyledWell>
          </Col>
        </Row>
        <TeamsMembers
          members={this.state.users}
          updateUsersCallback={this.updateUsersCallback}
          teamId={this.state.team.id}
        />
        <UpdateTeamDescriptionModal
          showModal={this.state.showModal}
          hideModal={this.hideDescriptionModalCallback}
          team={this.state.team}
          updateTeamCallback={this.updateTeamCallback}
        />
      </Wrapper>
    );
  }
}

SettingsTeamPageContainer.PropTypes = {
  match: ReactRouterPropTypes.match.isRequired
};

export default SettingsTeamPageContainer;
