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
import axios from "../../../../../config/axios";

import { TEXT_MAX_LENGTH } from "../../../../../config/constants/numeric";
import { TEAM_UPDATE_PATH } from "../../../../../config/api_endpoints";
import { COLOR_APPLE_BLOSSOM } from "../../../../../config/constants/colors";

const StyledHelpBlock = styled(HelpBlock)`
  color: ${COLOR_APPLE_BLOSSOM}
`;

class UpdateTeamDescriptionModal extends Component {
  constructor(props) {
    super(props);
    this.state = { errorMessage: "", description: "" };
    this.onCloseModal = this.onCloseModal.bind(this);
    this.updateDescription = this.updateDescription.bind(this);
    this.handleDescription = this.handleDescription.bind(this);
    this.getValidationState = this.getValidationState.bind(this);
  }

  onCloseModal() {
    this.setState({ errorMessage: "", description: "" });
    this.props.hideModal();
  }

  getValidationState() {
    return this.state.errorMessage.length > 0 ? "error" : null;
  }

  handleDescription(el) {
    const { value } = el.target;
    if (value.length > TEXT_MAX_LENGTH) {
      this.setState({
        errorMessage: (
          <FormattedMessage
            id="error_messages.text_too_long"
            values={{ max_length: TEXT_MAX_LENGTH }}
          />
        )
      });
    } else {
      this.setState({ errorMessage: "", description: value });
    }
  }

  updateDescription() {
    axios({
      method: "post",
      url: TEAM_UPDATE_PATH,
      withCredentials: true,
      data: {
        team_id: this.props.team.id,
        team: { description: this.state.description }
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
            <FormattedMessage id="settings_page.update_team_description_modal.title" />
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <FormGroup
            controlId="teamDescription"
            validationState={this.getValidationState()}
          >
            <ControlLabel>
              <FormattedMessage id="settings_page.update_team_description_modal.label" />
            </ControlLabel>
            <FormControl
              componentClass="textarea"
              defaultValue={this.props.team.description}
              onChange={this.handleDescription}
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
            onClick={this.updateDescription}
            disabled={!_.isEmpty(this.state.errorMessage)}
          >
            <FormattedMessage id="general.update" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

UpdateTeamDescriptionModal.propTypes = {
  showModal: bool.isRequired,
  hideModal: func.isRequired,
  team: PropTypes.shape({
    id: number.isRequired,
    description: string
  }).isRequired,
  updateTeamCallback: func.isRequired
};

export default UpdateTeamDescriptionModal;
