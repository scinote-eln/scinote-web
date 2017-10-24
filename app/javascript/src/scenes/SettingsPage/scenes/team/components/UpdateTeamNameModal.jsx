import React, { Component } from "react";
import PropTypes, { bool, number, string, func } from "prop-types";
import {
  Modal,
  Button,
  ControlLabel,
  FormControl,
} from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import axios from "../../../../../config/axios";
import {
  ValidatedForm,
  ValidatedFormGroup,
  ValidatedFormControl,
  ValidatedErrorHelpBlock,
  ValidatedSubmitButton
} from "../../../../../components/validation";
import {
  nameLengthValidator
} from "../../../../../components/validation/validators/text";

import { TEAM_UPDATE_PATH } from "../../../../../config/api_endpoints";

class UpdateTeamNameModal extends Component {
  constructor(props) {
    super(props);
    this.state = { name: props.team.name };
    this.onCloseModal = this.onCloseModal.bind(this);
    this.updateName = this.updateName.bind(this);
    this.handleName = this.handleName.bind(this);
  }

  onCloseModal() {
    this.setState({ name: "" });
    this.props.hideModal();
  }

  handleName(e) {
    this.setState({ name: e.target.value });
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
      .catch(error => {
        this.form.setErrorsForTag("name", [error.message]);
      });
  }

  render() {
    return (
      <Modal show={this.props.showModal} onHide={this.onCloseModal}>
        <ValidatedForm ref={(f) => { this.form = f; }}>
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
            <ValidatedSubmitButton
              onClick={this.updateName}
              bsStyle="primary"
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
