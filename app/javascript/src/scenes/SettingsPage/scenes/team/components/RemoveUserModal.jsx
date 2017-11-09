// @flow

import React, { Component } from "react";
import { Modal, Button, Alert, Glyphicon } from "react-bootstrap";
import { FormattedMessage, FormattedHTMLMessage } from "react-intl";
import type { Team$TeamMemeber } from "flow-typed";
import { removeUserFromTeam } from "../../../../../services/api/user_team_api";


type Props = {
  showModal: boolean,
  hideModal: Function,
  updateUsersCallback: Function,
  userToRemove: Team$TeamMemeber
};

class RemoveUserModal extends Component<Props> {
  constructor(props: Props) {
    super(props);
    (this: any).onCloseModal = this.onCloseModal.bind(this);
    (this: any).removeUser = this.removeUser.bind(this);
  }

  onCloseModal(): void {
    this.props.hideModal();
  }

  removeUser(): void {
    const { teamId, teamUserId } = this.props.userToRemove;
    removeUserFromTeam(teamId, teamUserId)
      .then(response => {
        this.props.updateUsersCallback(response);
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
        <Modal.Body className="remove-user-modal-body">
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
          <Button bsStyle="primary" onClick={this.removeUser}>
            <FormattedMessage id="settings_page.remove_user_modal.remove_user" />
          </Button>
          <Button onClick={this.onCloseModal}>
            <FormattedMessage id="general.close" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

export default RemoveUserModal;
