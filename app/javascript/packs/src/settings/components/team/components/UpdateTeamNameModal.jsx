import React, { Component } from "react";
import PropTypes, { bool, number, string, func } from "prop-types";
import {
  Modal,
  Button,
  FormGroup,
  ControlLabel,
  FormControl,
  HelpBlock
} from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import _ from "lodash";
import styled from "styled-components";
import axios from "../../../../../app/axios";

import { NAME_MAX_LENGTH } from "../../../../../app/constants/numeric";
import { TEAM_UPDATE_PATH } from "../../../../../app/routes";
import { COLOR_APPLE_BLOSSOM } from "../../../../../app/constants/colors";

const StyledHelpBlock = styled(HelpBlock)`
  color: ${COLOR_APPLE_BLOSSOM}
`;

class UpdateTeamNameModal extends Component {
  constructor(props) {
    super(props);
    this.state = { errorMessage: "", name: props.team.name};
    this.onCloseModal = this.onCloseModal.bind(this);
    this.updateName = this.updateName.bind(this);
    this.handleName = this.handleName.bind(this);
    this.getValidationState = this.getValidationState.bind(this);
  }

  onCloseModal() {
    this.setState({ errorMessage: "", name: "" });
    this.props.hideModal();
  }

  getValidationState() {
    if (this.state.errorMessage.length > 0) {
      return "error";
    }
    return null;
  }

  handleName(el) {
    const { value } = el.target;
    if (value.length > NAME_MAX_LENGTH) {
      this.setState({
        errorMessage: (
          <FormattedMessage
            id="error_messages.text_too_long"
            values={{ max_length: NAME_MAX_LENGTH }}
          />
        )
      });
    } else {
      this.setState({ errorMessage: "", name: value });
    }
  }

  updateName() {
    axios({
      method: "post",
      url: TEAM_UPDATE_PATH,
      withCredentials: true,
      data: {
        team_id: this.props.team.id,
        team: { name: this.state.name }
      }
    })
      .then(response => {
        this.props.updateTeamCallback(response.data.team);
        this.onCloseModal();
      })
      .catch(error => this.setState({ errorMessage: error.message }));
  }

  render() {
    return (
      <Modal show={this.props.showModal} onHide={this.onCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            <FormattedMessage id="settings_page.update_team_name_modal.title" />
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <FormGroup
            controlId="teamName"
            validationState={this.getValidationState()}
          >
            <ControlLabel>
              <FormattedMessage id="settings_page.update_team_name_modal.label" />
            </ControlLabel>
            <FormControl
              type="text"
              onChange={this.handleName}
              value={this.state.name}
            />
            <FormControl.Feedback />
            <StyledHelpBlock>
              {this.state.errorMessage}
            </StyledHelpBlock>
          </FormGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={this.onCloseModal}>
            <FormattedMessage id="general.close" />
          </Button>
          <Button
            bsStyle="success"
            onClick={this.updateName}
            disabled={!_.isEmpty(this.state.errorMessage)}
          >
            <FormattedMessage id="general.update" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

UpdateTeamNameModal.propTypes = {
  showModal: bool.isRequired,
  hideModal: func.isRequired,
  team: PropTypes.shape({
    id: number.isRequired,
    name: string
  }).isRequired,
  updateTeamCallback: func.isRequired
};

export default UpdateTeamNameModal;
