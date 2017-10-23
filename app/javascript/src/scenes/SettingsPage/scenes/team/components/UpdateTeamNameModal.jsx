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

import { NAME_MAX_LENGTH } from "../../../../../config/constants/numeric";
import { COLOR_APPLE_BLOSSOM } from "../../../../../config/constants/colors";

const StyledHelpBlock = styled(HelpBlock)`
  color: ${COLOR_APPLE_BLOSSOM};
`;

type Team = {
  id: number,
  name: string
};

type State = {
  errorMessage: Node,
  name: string
}

type Props = {
  showModal: boolean,
  hideModal: Function,
  team: Team,
  updateTeamCallback: Function
};

class UpdateTeamNameModal extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    (this: any).state = { errorMessage: "", name: props.team.name };
    (this: any).onCloseModal = this.onCloseModal.bind(this);
    (this: any).updateName = this.updateName.bind(this);
    (this: any).handleName = this.handleName.bind(this);
    (this: any).getValidationState = this.getValidationState.bind(this);
  }

  onCloseModal(): void {
    (this: any).setState({ errorMessage: "", name: "" });
    this.props.hideModal();
  }

  getValidationState(): string | null {
    return String(this.state.errorMessage).length > 0 ? "error" : null;
  }

  handleName(el: SyntheticEvent<HTMLButtonElement>): void {
    const { value } = el.currentTarget;
    if (value.length > NAME_MAX_LENGTH) {
      (this: any).setState({
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

  updateName(): void {
    updateTeam(this.props.team.id, { name: this.state.name })
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
            <StyledHelpBlock>{this.state.errorMessage}</StyledHelpBlock>
          </FormGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button
            bsStyle="primary"
            onClick={this.updateName}
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

export default UpdateTeamNameModal;
