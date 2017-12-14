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
import { textMaxLengthValidator } from "../../../../../components/validation/validators/text";
import { updateTeam } from "../../../../../services/api/teams_api";

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
  description: string
};

class UpdateTeamDescriptionModal extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { description: "" };
    (this: any).onCloseModal = this.onCloseModal.bind(this);
    (this: any).updateDescription = this.updateDescription.bind(this);
    (this: any).handleDescription = this.handleDescription.bind(this);
  }

  onCloseModal(): void {
    (this: any).setState({ description: "" });
    this.props.hideModal();
  }

  handleDescription(e: SyntheticInputEvent<HTMLInputElement>): void {
    (this: any).setState({ description: e.target.value });
  }

  updateDescription(): void {
    updateTeam(this.props.team.id, { description: this.state.description })
      .then(response => {
        this.props.updateTeamCallback(response);
        this.onCloseModal();
      })
      .catch(error => {
        (this: any).form.setErrorsForTag('description', error.response.data.message)
      });
  }

  render(): Node {
    return (
      <Modal show={this.props.showModal} onHide={this.onCloseModal}>
        <ValidatedForm
          ref={f => {
            (this: any).form = f;
          }}
        >
          <Modal.Header closeButton>
            <Modal.Title>
              <FormattedMessage id="settings_page.update_team_description_modal.title" />
            </Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <ValidatedFormGroup tag="description">
              <ControlLabel>
                <FormattedMessage id="settings_page.update_team_description_modal.label" />
              </ControlLabel>
              <ValidatedFormControl
                id="teamDescription"
                componentClass="textarea"
                tag="description"
                defaultValue={this.props.team.description}
                onChange={this.handleDescription}
                validatorsOnChange={[textMaxLengthValidator]}
              />
              <FormControl.Feedback />
              <ValidatedErrorHelpBlock tag="description" />
            </ValidatedFormGroup>
          </Modal.Body>
          <Modal.Footer>
            <ValidatedSubmitButton
              bsStyle="primary"
              onClick={this.updateDescription}
            >
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

export default UpdateTeamDescriptionModal;
