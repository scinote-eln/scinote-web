// @flow

import React, { Component } from "react";
import { FormattedMessage } from "react-intl";
import { Modal, ButtonToolbar, Button } from "react-bootstrap";
import styled from "styled-components";

import { inviteUsersToTeam } from "../../services/api/user_team_api";
import { getTeamDetails } from "../../services/api/teams_api";

import InviteUsersForm from "./components/InviteUsersForm";
import InviteUsersResults from "./components/InviteUsersResults";
import InviteUsersButton from "./components/InviteUsersButton";

const StyledButtonToolbar = styled(ButtonToolbar)`
  float: right;
`;


type Team = {
  id: number,
  name: string
}

type Props = {
  showModal: boolean,
  onCloseModal: Function,
  team: Team,
  updateUsersCallback: Function
};

type State = {
  inviteUserButtonDisabled: boolean,
  showInviteUsersResults: boolean,
  inputTags: Array<string>,
  inviteResults: Array<string>
};

class InviteUsersModal extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    (this: any).state = {
      inviteUserButtonDisabled: true,
      showInviteUsersResults: false,
      inputTags: [],
      inviteResults: []
    };
    (this: any).handleInputChange = this.handleInputChange.bind(this);
    (this: any).inviteAs = this.inviteAs.bind(this);
    (this: any).handleCloseModal = this.handleCloseModal.bind(this);
  }

  handleCloseModal(): void {
    this.props.onCloseModal();
    (this: any).setState({
      showInviteUsersResults: false,
      inputTags: [],
      inviteResults: []
    });
    // Update team members table
    getTeamDetails(this.props.team.id).then(response => {
      const { users } = response;
      this.props.updateUsersCallback(users);
    });
  }

  handleInputChange(inputTags: Array<string>): void {
    if (inputTags.length > 0) {
      (this: any).setState({ inputTags, inviteUserButtonDisabled: false });
    } else {
      (this: any).setState({ inputTags, inviteUserButtonDisabled: true });
    }
  }

  inviteAs(role: number): void {
    inviteUsersToTeam(role, this.state.inputTags, this.props.team.id)
      .then(response => {
        (this: any).setState({
          inviteResults: response,
          showInviteUsersResults: true,
          inviteUserButtonDisabled: true
        });
      })
      .catch(error => {
        console.log("Invite As Error: ", error);
        if (error.response) {
          console.log("Error message: ", error.response.data);
          // TO DO: put this error in flash msg
        }
      });
  }

  render() {
    let modalBody = null;
    let inviteButton = null;
    if (this.state.showInviteUsersResults) {
      modalBody = <InviteUsersResults results={this.state.inviteResults} />;
      inviteButton = null;
    } else {
      modalBody = (
        <InviteUsersForm
          tags={this.state.inputTags}
          handleChange={this.handleInputChange}
          teamName={this.props.team.name}
        />
      );
      inviteButton = (
        <InviteUsersButton
          handleClick={this.inviteAs}
          status={this.state.inviteUserButtonDisabled}
        />
      );
    }

    return (
      <Modal
        show={this.props.showModal}
        onHide={this.handleCloseModal}
        restoreFocus={false}
      >
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage
              id="invite_users.modal_title"
              values={{
                team: this.props.team.name
              }}
            />
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>{modalBody}</Modal.Body>
        <Modal.Footer>
          <StyledButtonToolbar>
            {inviteButton}
            <Button onClick={this.handleCloseModal}>
              <FormattedMessage
                id={`general.${this.state.showInviteUsersResults
                  ? "close"
                  : "cancel"}`}
              />
            </Button>
          </StyledButtonToolbar>
        </Modal.Footer>
      </Modal>
    );
  }
}

export default InviteUsersModal;
