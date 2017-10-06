import React, { Component } from "react";
import { bool, func, shape, number, string } from "prop-types";
import { FormattedMessage } from "react-intl";
import { Modal, ButtonToolbar, Button } from "react-bootstrap";
import styled from "styled-components";
import axios from "../../config/axios";

import {
  INVITE_USERS_PATH,
  TEAM_DETAILS_PATH
} from "../../config/api_endpoints";
import InviteUsersForm from "./components/InviteUsersForm";
import InviteUsersResults from "./components/InviteUsersResults";
import InviteUsersButton from "./components/InviteUsersButton";

const StyledButtonToolbar = styled(ButtonToolbar)`float: right;`;

class InviteUsersModal extends Component {
  constructor(props) {
    super(props);
    this.state = {
      showInviteUsersResults: false,
      inputTags: [],
      inviteResults: []
    };
    this.handleInputChange = this.handleInputChange.bind(this);
    this.inviteAs = this.inviteAs.bind(this);
    this.handleCloseModal = this.handleCloseModal.bind(this);
  }

  handleCloseModal() {
    const path = TEAM_DETAILS_PATH.replace(":team_id", this.props.team.id);
    this.props.onCloseModal();
    this.setState({
      showInviteUsersResults: false,
      inputTags: [],
      inviteResults: []
    });
    // Update team members table
    axios.get(path).then(response => {
      const { users } = response.data.team_details;
      this.props.updateUsersCallback(users);
    });
  }

  handleInputChange(inputTags) {
    this.setState({ inputTags });
  }

  inviteAs(role) {
    axios
      .put(INVITE_USERS_PATH, {
        user_role: role,
        emails: this.state.inputTags,
        team_id: this.props.team.id
      })
      .then(({ data }) => {
        this.setState({ inviteResults: data, showInviteUsersResults: true });
      })
      .catch(error => {
        console.log("Invite As Error: ", error);
        if (error.response) {
          console.log("Error message:", error.response.data);
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
      inviteButton = <InviteUsersButton handleClick={this.inviteAs} />;
    }

    return (
      <Modal show={this.props.showModal} onHide={this.handleCloseModal}>
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

InviteUsersModal.propTypes = {
  showModal: bool.isRequired,
  onCloseModal: func.isRequired,
  team: shape({ id: number.isRequired, name: string.isRequired }).isRequired,
  updateUsersCallback: func.isRequired
};

export default InviteUsersModal;
