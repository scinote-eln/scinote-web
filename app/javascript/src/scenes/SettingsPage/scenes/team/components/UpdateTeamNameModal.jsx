// @flow
import React, { Component } from "react";
import type { Node } from "react";
import { Modal, Button, ControlLabel, FormControl } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import {
  ValidatedForm,
  ValidatedFormGroup,
  ValidatedFormControl,
  ValidatedErrorHelpBlock,
  ValidatedSubmitButton
} from "../../../../../components/validation";
import { nameLengthValidator } from "../../../../../components/validation/validators/text";
import { updateTeam } from "../../../../../services/api/teams_api";

type Team = {
  id: number,
  name: string
};

type State = {
  name: string
};

type Props = {
  showModal: boolean,
  hideModal: Function,
  team: Team,
  updateTeamCallback: Function
};

class UpdateTeamNameModal extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { name: props.team.name };
    (this: any).onCloseModal = this.onCloseModal.bind(this);
    (this: any).updateName = this.updateName.bind(this);
    (this: any).handleName = this.handleName.bind(this);
  }

  onCloseModal(): void {
    (this: any).setState({ name: "" });
    this.props.hideModal();
  }

  handleName(e: SyntheticInputEvent<HTMLInputElement>): void {
    (this: any).setState({ name: e.target.value });
  }

  updateName(): void {
    updateTeam(this.props.team.id, { name: this.state.name })
      .then(response => {
        this.props.updateTeamCallback(response);
        this.onCloseModal();
      })
      .catch(error => {
        (this: any).form.setErrorsForTag("name", error.response.data.message);
      });
  }

  render(): Node {
    return (
      <Modal
        id="settings_page.update_team_name_modal"
        show={this.props.showModal}
        onHide={this.onCloseModal}
      >
        <ValidatedForm
          ref={f => {
            (this: any).form = f;
          }}
        >
          <Modal.Header closeButton>
            <Modal.Title>
              <FormattedMessage id="settings_page.update_team_name_modal.title" />
            </Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <ValidatedFormGroup tag="name">
              <ControlLabel>
                <FormattedMessage id="settings_page.update_team_name_modal.label" />
              </ControlLabel>
              <ValidatedFormControl
                type="text"
                tag="name"
                validatorsOnChange={[nameLengthValidator]}
                onChange={this.handleName}
                value={this.state.name}
              />
              <FormControl.Feedback />
              <ValidatedErrorHelpBlock tag="name" />
            </ValidatedFormGroup>
          </Modal.Body>
          <Modal.Footer>
            <ValidatedSubmitButton onClick={this.updateName} bsStyle="primary">
              <FormattedMessage id="general.update" />
            </ValidatedSubmitButton>
            <Button onClick={this.onCloseModal}>
              <FormattedMessage id="general.close" />
            </Button>
          </Modal.Footer>
        </ValidatedForm>
      </Modal>
    );
  }
}

export default UpdateTeamNameModal;
