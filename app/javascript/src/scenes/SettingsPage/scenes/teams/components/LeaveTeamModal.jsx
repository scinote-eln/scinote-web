//  @flow
import React, { Component } from "react";
import type { Node } from "react";
import { Modal, Button, Alert, Glyphicon } from "react-bootstrap";
import { FormattedMessage, FormattedHTMLMessage } from "react-intl";
import { connect } from "react-redux";
import { leaveTeam } from "../../../../../services/api/teams_api";

import {
  addTeamsData,
  getCurrentTeam
} from "../../../../../components/actions/TeamsActions";

type Team = {
  id: number,
  name: string,
  user_team_id: number
};

type Props = {
  updateTeamsState: Function,
  showModal: boolean,
  team: Team,
  addTeamsData: Function,
  hideLeaveTeamModal: Function,
  getCurrentTeam: Function
};

class LeaveTeamModal extends Component<Props> {
  constructor(props: Props) {
    super(props);
    (this: any).onCloseModal = this.onCloseModal.bind(this);
    (this: any).leaveTeam = this.leaveTeam.bind(this);
  }

  onCloseModal(): void {
    this.props.hideLeaveTeamModal();
  }

  leaveTeam(): void {
    const { id, user_team_id } = this.props.team;
    leaveTeam(id, user_team_id)
      .then(response => {
        this.props.updateTeamsState(response);
        this.props.addTeamsData(response);
        this.props.getCurrentTeam();
      })
      .catch(error => {
        console.log("error: ", error.response.data.message);
      });
    this.props.hideLeaveTeamModal();
  }

  render(): Node {
    return (
      <Modal show={this.props.showModal} onHide={this.onCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage
              id="settings_page.leave_team_modal.title"
              values={{ teamName: this.props.team.name }}
            />
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            <FormattedMessage
              id="settings_page.leave_team_modal.subtitle"
              values={{ teamName: this.props.team.name }}
            />
          </p>
          <Alert bsStyle="danger">
            <Glyphicon glyph="exclamation-sign" />&nbsp;
            <FormattedMessage id="settings_page.leave_team_modal.warnings" />
            <ul>
              <li>
                <FormattedMessage id="settings_page.leave_team_modal.warning_message_one" />
              </li>
              <li>
                <FormattedHTMLMessage id="settings_page.leave_team_modal.warning_message_two" />
              </li>
              <li>
                <FormattedMessage id="settings_page.leave_team_modal.warning_message_three" />
              </li>
            </ul>
          </Alert>
        </Modal.Body>
        <Modal.Footer>
          <Button bsStyle="primary" onClick={this.leaveTeam}>
            <FormattedMessage id="settings_page.leave_team_modal.leave_team" />
          </Button>
          <Button onClick={this.onCloseModal}>
            <FormattedMessage id="general.close" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

export default connect(null, {
  addTeamsData,
  getCurrentTeam
})(LeaveTeamModal);
