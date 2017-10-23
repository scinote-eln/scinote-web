import React, { Component } from "react";
import PropTypes, { bool, number, string, func } from "prop-types";
import { Modal, Button, Alert, Glyphicon } from "react-bootstrap";
import { FormattedMessage, FormattedHTMLMessage } from "react-intl";
import { connect } from "react-redux";
import { leaveTeam } from "../../../../../services/api/teams_api";

import {
  addTeamsData,
  setCurrentTeam
} from "../../../../../components/actions/TeamsActions";

class LeaveTeamModal extends Component {
  constructor(props) {
    super(props);
    this.onCloseModal = this.onCloseModal.bind(this);
    this.leaveTeam = this.leaveTeam.bind(this);
  }

  onCloseModal() {
    this.props.hideLeaveTeamModel();
  }

  leaveTeam() {
    const { id, user_team_id } = this.props.team;
    leaveTeam(id, user_team_id)
      .then(response => {
        const { teams, currentTeam } = response;
        this.props.updateTeamsState(teams);
        this.props.addTeamsData(teams);
        this.props.setCurrentTeam(currentTeam);
      })
      .catch(error => {
        console.log("error: ", error.response.data.message);
      });
    this.props.hideLeaveTeamModel();
  }

  render() {
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

LeaveTeamModal.propTypes = {
  updateTeamsState: func.isRequired,
  showModal: bool.isRequired,
  team: PropTypes.shape({
    id: number.isRequired,
    name: string.isRequired,
    user_team_id: number.isRequired
  }).isRequired,
  addTeamsData: func.isRequired,
  hideLeaveTeamModel: func.isRequired,
  setCurrentTeam: func.isRequired
};

export default connect(null, {
  addTeamsData,
  setCurrentTeam
})(LeaveTeamModal);
