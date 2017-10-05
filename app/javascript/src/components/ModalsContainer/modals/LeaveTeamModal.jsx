import React, { Component } from "react";
import PropTypes, { bool, number, string, func } from "prop-types";
import { Modal, Button, Alert, Glyphicon } from "react-bootstrap";
import { FormattedMessage, FormattedHTMLMessage } from "react-intl";
import { connect } from "react-redux";
import axios from "../../../config/axios";

import { LEAVE_TEAM_PATH } from "../../../config/api_endpoints";
import {
  addTeamsData,
  setCurrentTeam,
  leaveTeamModalShow
} from "../../actions/TeamsActions";

class LeaveTeamModal extends Component {
  constructor(props) {
    super(props);
    this.onCloseModal = this.onCloseModal.bind(this);
    this.leaveTeam = this.leaveTeam.bind(this);
  }

  onCloseModal() {
    this.props.leaveTeamModalShow(false);
  }

  leaveTeam() {
    const teamUrl = `${LEAVE_TEAM_PATH}?team=${this.props.team
      .id}&user_team=${this.props.team.user_team_id}`;
    axios
      .delete(teamUrl, {
        withCredentials: true
      })
      .then(response => {
        const teams = response.data.teams.collection;
        this.props.addTeamsData(teams);
        const currentTeam = _.find(teams, team => team.current_team);
        this.props.setCurrentTeam(currentTeam);
      })
      .catch(error => {
        console.log("error: ", error.response.data.message);
      });
    this.props.leaveTeamModalShow(false);
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
          <Button onClick={this.onCloseModal}>
            <FormattedMessage id="general.close" />
          </Button>
          <Button bsStyle="success" onClick={this.leaveTeam}>
            <FormattedMessage id="settings_page.leave_team_modal.leave_team" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

LeaveTeamModal.propTypes = {
  showModal: bool.isRequired,
  team: PropTypes.shape({
    id: number.isRequired,
    name: string.isRequired,
    user_team_id: number.isRequired
  }).isRequired,
  addTeamsData: func.isRequired,
  leaveTeamModalShow: func.isRequired,
  setCurrentTeam: func.isRequired
};

const mapStateToProps = ({ showLeaveTeamModal }) => ({
  showModal: showLeaveTeamModal.show,
  team: showLeaveTeamModal.team
});

export default connect(mapStateToProps, {
  leaveTeamModalShow,
  addTeamsData,
  setCurrentTeam
})(LeaveTeamModal);
