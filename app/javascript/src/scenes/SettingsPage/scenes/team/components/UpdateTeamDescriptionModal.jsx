// @flow

import React, { Component } from "react";
import type { Node } from "react";
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
import { updateTeam } from "../../../../../services/api/teams_api";
import { TEXT_MAX_LENGTH } from "../../../../../config/constants/numeric";
import { COLOR_APPLE_BLOSSOM } from "../../../../../config/constants/colors";

const StyledHelpBlock = styled(HelpBlock)`
  color: ${COLOR_APPLE_BLOSSOM};
`;

type Team = {
  id: number,
  description: string
};

type Props = {
  showModal: boolean,
  hideModal: Function,
  team: Team,
  updateTeamCallback: Function
};

type State = {
  errorMessage: Node,
  description: string
};

class UpdateTeamDescriptionModal extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    (this: any).state = { errorMessage: "", description: "" };
    (this: any).onCloseModal = this.onCloseModal.bind(this);
    (this: any).updateDescription = this.updateDescription.bind(this);
    (this: any).handleDescription = this.handleDescription.bind(this);
    (this: any).getValidationState = this.getValidationState.bind(this);
  }

  onCloseModal(): void {
    (this: any).setState({ errorMessage: "", description: "" });
    this.props.hideModal();
  }

  getValidationState(): string | null {
    return String(this.state.errorMessage).length > 0 ? "error" : null;
  }

  handleDescription(el: SyntheticEvent<HTMLButtonElement>): void {
    const { value } = el.currentTarget;
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
      (this: any).setState({ errorMessage: "", description: value });
    }
  }

  updateDescription(): void {
    updateTeam(this.props.team.id, { description: this.state.description })
      .then(response => {
        this.props.updateTeamCallback(response);
        this.onCloseModal();
      })
      .catch(error => this.setState({ errorMessage: error.message }));
  }

  render(): Node {
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
            <StyledHelpBlock>{this.state.errorMessage}</StyledHelpBlock>
          </FormGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button
            bsStyle="primary"
            onClick={this.updateDescription}
            disabled={!_.isEmpty(this.state.errorMessage)}
          >
            <FormattedMessage id="general.update" />
          </Button>
          <Button onClick={this.onCloseModal}>
            <FormattedMessage id="general.close" />
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

export default UpdateTeamDescriptionModal;
