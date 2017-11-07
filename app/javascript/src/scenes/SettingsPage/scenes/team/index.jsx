// @flow

import React, { Component } from "react";
import styled from "styled-components";
import { Breadcrumb, Row, Col, Glyphicon, Well } from "react-bootstrap";
import { LinkContainer } from "react-router-bootstrap";
import { FormattedHTMLMessage, FormattedMessage } from "react-intl";
import moment from "moment";
import type { Match } from "react-router-dom";
import type { Teams$Team, Team$TeamMemeber } from "flow-typed";

import { formatBytes } from "../../../../services/helpers/units_converter_helper";
import { getTeamDetails } from "../../../../services/api/teams_api";

import { SETTINGS_TEAMS_ROUTE } from "../../../../config/routes";
import { BORDER_LIGHT_COLOR } from "../../../../config/constants/colors";

import PageTitle from "../../../../components/PageTitle";
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

const TabTitle = styled.div`
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
  padding: 9px;
  & > span {
    padding-left: 5px;
  }
`;

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

type Props = {
  tabState: Function,
  match: Match
};

type State = {
  showDescriptionModal: boolean,
  showNameModal: boolean,
  users: Array<Team$TeamMemeber>,
  team: Teams$Team
};

class SettingsTeam extends Component<Props, State> {
  constructor(props: Props) {
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
    (this: any).showDescriptionModal = this.showDescriptionModal.bind(this);
    (this: any).hideDescriptionModalCallback = this.hideDescriptionModalCallback.bind(
      this
    );
    (this: any).updateTeamCallback = this.updateTeamCallback.bind(this);
    (this: any).updateUsersCallback = this.updateUsersCallback.bind(this);
    (this: any).showNameModal = this.showNameModal.bind(this);
    (this: any).hideNameModalCallback = this.hideNameModalCallback.bind(this);
    (this: any).renderEditNameModal = this.renderEditNameModal.bind(this);
  }

  componentDidMount(): void {
    // set team tab on active
    (this: any).props.tabState("2");
    const { id } = this.props.match.params;
    if (id) {
      getTeamDetails(parseInt(id)).then(response => {
        const { team, users } = response;
        (this: any).setState({ users, team });
      });
    }
  }

  showDescriptionModal(): void {
    (this: any).setState({ showDescriptionModal: true });
  }

  hideDescriptionModalCallback(): void {
    (this: any).setState({ showDescriptionModal: false });
  }

  showNameModal(): void {
    (this: any).setState({ showNameModal: true });
  }

  hideNameModalCallback(): void {
    (this: any).setState({ showNameModal: false });
  }

  updateTeamCallback(team: Teams$Team): void {
    (this: any).setState({ team });
  }

  updateUsersCallback(users: Array<Team$TeamMemeber>): void {
    (this: any).setState({ users });
  }

  renderDescription() {
    if (this.state.team.description) {
      return this.state.team.description;
    }
    return (
      <FormattedHTMLMessage id="settings_page.single_team.no_description" />
    );
  }

  renderEditNameModal() {
    if (this.state.showNameModal) {
      return (
        <UpdateTeamNameModal
          showModal={this.state.showNameModal}
          hideModal={this.hideNameModalCallback}
          team={this.state.team}
          updateTeamCallback={this.updateTeamCallback}
        />
      );
    }
    return <span />;
  }

  render() {
    return (
      <PageTitle
        localeID="page_title.team_page"
        values={{ name: this.state.team.name }}
      >
        <Wrapper>
          <Breadcrumb>
            <LinkContainer to={SETTINGS_TEAMS_ROUTE}>
              <Breadcrumb.Item>
                <FormattedMessage id="settings_page.all_teams" />
              </Breadcrumb.Item>
            </LinkContainer>
            <Breadcrumb.Item active>
              {this.state.team.name}
            </Breadcrumb.Item>
          </Breadcrumb>
          <TabTitle>
            <StyledH3 className="team-name-title" onClick={this.showNameModal}>
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
                    space_usage: formatBytes(this.state.team.space_taken)
                  }}
                />
              </StyledWell>
            </Col>
          </Row>
          <Row>
            <Col className="team-description" sm={12} onClick={this.showDescriptionModal}>
              <BadgeWrapper>
                <Glyphicon glyph="info-sign" />
              </BadgeWrapper>
              <StyledDescriptionWell>
                <span>{this.renderDescription()}</span>
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
          {this.renderEditNameModal()}
        </Wrapper>
      </PageTitle>
    );
  }
}

export default SettingsTeam;
