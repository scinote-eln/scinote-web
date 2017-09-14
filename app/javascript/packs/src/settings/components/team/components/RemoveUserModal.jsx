import React, { Component } from "react";
import PropTypes, { bool, number, string, func } from "prop-types";
import { Modal, Button, Alert, Glyphicon } from "react-bootstrap";
import { FormattedMessage, FormattedHTMLMessage } from "react-intl";

import axios from "../../../../../app/axios";

import { REMOVE_USER_FROM_TEAM_PATH } from "../../../../../app/routes";

class RemoveUserModal extends Component {
  constructor(props) {
    super(props);
    this.onCloseModal = this.onCloseModal.bind(this);
    this.removeUser = this.removeUser.bind(this);
  }

  onCloseModal() {
    this.props.hideModal();
  }

  removeUser() {
    const { team_id, team_user_id } = this.props.userToRemove;
    axios({
      method: "DELETE",
      url: REMOVE_USER_FROM_TEAM_PATH,
      withCredentials: true,
      data: {
        team: team_id,
        user_team: team_user_id
      }
    })
      .then(response => {
        this.props.updateUsersCallback(response.data.team_users);
        this.props.hideModal();
      })
      .catch(error => console.log(error));
  }

  render() {
    const { teamName, userName } = this.props.userToRemove;
    return (
      <Modal show={this.props.showModal} onHide={this.onCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage
              id="settings_page.remove_user_modal.title"
              values={{ user: userName, team: teamName }}
            />
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            <FormattedMessage
              id="settings_page.remove_user_modal.subtitle"
              values={{ user: userName, team: teamName }}
            />
          </p>
          <Alert bsStyle="danger">
            <Glyphicon glyph="exclamation-sign" />&nbsp;
            <FormattedMessage id="settings_page.remove_user_modal.warnings" />
            <ul>
              <li>
                <FormattedMessage id="settings_page.remove_user_modal.warning_message_one" />
              </li>
              <li>
                <FormattedHTMLMessage id="settings_page.remove_user_modal.warning_message_two" />
              </li>
              <li>
                <FormattedMessage id="settings_page.remove_user_modal.warning_message_three" />
              </li>
            </ul>
          </Alert>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={this.onCloseModal}>
            <FormattedMessage id="general.close" />
          </Button>
          <Button bsStyle="success" onClick={this.removeUser}>
            <FormattedMessage id="settings_page.remove_user_modal.remove_user" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

RemoveUserModal.propTypes = {
  showModal: bool.isRequired,
  hideModal: func.isRequired,
  userToRemove: PropTypes.shape({
    userName: string.isRequired,
    team_user_id: number.isRequired,
    teamName: string.isRequired,
    team_id: number.isRequired
  }).isRequired,
  updateUsersCallback: func.isRequired
};

export default RemoveUserModal;
