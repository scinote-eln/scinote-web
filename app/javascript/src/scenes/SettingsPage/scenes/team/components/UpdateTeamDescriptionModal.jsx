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
  textMaxLengthValidator
} from "../../../../../components/validation/validators/text";

import { TEAM_UPDATE_PATH } from "../../../../../config/api_endpoints";

class UpdateTeamDescriptionModal extends Component {
  constructor(props) {
    super(props);
    this.state = { description: "" };
    this.onCloseModal = this.onCloseModal.bind(this);
    this.updateDescription = this.updateDescription.bind(this);
    this.handleDescription = this.handleDescription.bind(this);
  }

  onCloseModal() {
    this.setState({ description: "" });
    this.props.hideModal();
  }

  handleDescription(el) {
    this.setState({ description: el.target.value });
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
        <ValidatedForm ref={(f) => { this.form = f; }}>
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
