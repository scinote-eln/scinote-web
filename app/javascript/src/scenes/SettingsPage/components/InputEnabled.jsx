import React, { Component } from "react";
import { string, func } from "prop-types";
import _ from "lodash";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";
import {
  FormGroup,
  FormControl,
  ControlLabel,
  Button,
  HelpBlock
} from "react-bootstrap";
import { updateUser } from "../../../services/api/users_api";

import {
  BORDER_LIGHT_COLOR,
  COLOR_APPLE_BLOSSOM
} from "../../../config/constants/colors";
import {
  ENTER_KEY_CODE,
  USER_INITIALS_MAX_LENGTH,
  NAME_MAX_LENGTH,
  PASSWORD_MAX_LENGTH,
  PASSWORD_MIN_LENGTH
} from "../../../config/constants/numeric";
import { EMAIL_REGEX } from "../../../config/constants/strings";

const StyledInputEnabled = styled.div`
  border: 1px solid ${BORDER_LIGHT_COLOR};
  padding: 19px;
  margin: 20px 0;

  input {
    margin-bottom: 15px;
  }
`;

const StyledHelpBlock = styled(HelpBlock)`color: ${COLOR_APPLE_BLOSSOM};`;

const ErrorMsg = styled.div`color: red;`;

class InputEnabled extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: this.props.inputValue,
      password_confirmation: "",
      errorMessage: ""
    };

    this.handleChange = this.handleChange.bind(this);
    this.handlePasswordConfirmation = this.handlePasswordConfirmation.bind(
      this
    );
    this.handleKeyPress = this.handleKeyPress.bind(this);
    this.confirmationField = this.confirmationField.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.getValidationState = this.getValidationState.bind(this);
    this.handleFullNameValidation = this.handleFullNameValidation.bind(this);
    this.handleEmailValidation = this.handleEmailValidation.bind(this);
    this.handleInitialsValidation = this.handleInitialsValidation.bind(this);
    this.handlePasswordConfirmationValidation = this.handlePasswordConfirmationValidation.bind(
      this
    );
  }

  getValidationState() {
    return this.state.errorMessage.length > 0 ? "error" : null;
  }

  handleKeyPress(event) {
    if (event.charCode === ENTER_KEY_CODE) {
      event.preventDefault();
      this.handleSubmit(event);
    }
  }

  handleChange(event) {
    switch (this.props.dataField) {
      case "full_name":
        this.handleFullNameValidation(event);
        break;
      case "email":
        this.handleEmailValidation(event);
        break;
      case "initials":
        this.handleInitialsValidation(event);
        break;
      case "password":
        this.handlePasswordValidation(event);
        break;
      default:
        this.setState({ value: event.target.value, errorMessage: "" });
    }
  }

  handlePasswordConfirmation(event) {
    const { value } = event.target;
    if (value.length === 0) {
      this.setState({ password_confirmation: value, errorMessage: "Banana" });
    }
    this.setState({ password_confirmation: value });
  }

  handleFullNameValidation(event) {
    const { value } = event.target;
    if (value.length > NAME_MAX_LENGTH) {
      this.setState({ value, errorMessage: "Banana" });
    } else if (value.length === 0) {
      this.setState({ value, errorMessage: "Banana" });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handleEmailValidation(event) {
    const { value } = event.target;
    if (!EMAIL_REGEX.test(value)) {
      this.setState({ value, errorMessage: "Banana" });
    } else if (value.length === 0) {
      this.setState({ value, errorMessage: "Banana" });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handleInitialsValidation(event) {
    const { value } = event.target;
    if (value.length > USER_INITIALS_MAX_LENGTH) {
      this.setState({ value, errorMessage: "Banana" });
    } else if (value.length === 0) {
      this.setState({ value, errorMessage: "Banana" });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handlePasswordValidation(event) {
    const { value } = event.target;
    if (value.length > PASSWORD_MAX_LENGTH) {
      this.setState({ value, errorMessage: "Banana" });
    } else if (value.length < PASSWORD_MIN_LENGTH) {
      this.setState({ value, errorMessage: "Banana" });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handlePasswordConfirmationValidation(event) {
    const { value } = event.target;
    if (value.length !== this.state.value) {
      this.setState({ value, errorMessage: "Banana" });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handleSubmit(event) {
    event.preventDefault();
    const { dataField } = this.props;
    let params = { [dataField]: this.state.value };
    if (dataField === "email" || dataField === "password") {
      params = _.merge(params, {
        password_confirmation: this.state.password_confirmation
      });
    }
    updateUser(params)
      .then(() => {
        this.props.reloadInfo();
        this.props.disableEdit();
      })
      .catch(({ response }) => {
        this.setState({ errorMessage: response.data.message.toString() });
      });
  }

  confirmationField() {
    const type = this.props.inputType;

    if (type === "email") {
      return (
        <div>
          <p>
            Current password (we need your current password to confirm your
            changes)
          </p>
          <FormControl
            type="password"
            value={this.state.password_confirmation}
            onChange={this.handlePasswordConfirmation}
          />
        </div>
      );
    }
    return "";
  }

  inputField() {
    const { inputType } = this.props;
    if (inputType === "password") {
      return (
        <div>
          <FormControl
            type={inputType}
            value={this.state.value}
            onChange={this.handleChange}
            onKeyPress={this.handleKeyPress}
            autoFocus
          />
          <p>New password confirmation</p>
          <FormControl
            type={inputType}
            value={this.state.password_confirmation}
            onChange={this.handlePasswordConfirmationValidation}
          />
        </div>
      );
    }
    return (
      <FormControl
        type={this.props.inputType}
        value={this.state.value}
        onChange={this.handleChange}
        onKeyPress={this.handleKeyPress}
        autoFocus
      />
    );
  }

  render() {
    return (
      <StyledInputEnabled>
        <form onSubmit={this.handleSubmit}>
          <FormGroup validationState={this.getValidationState()}>
            <h4>
              <FormattedMessage id="settings_page.change" />
              <FormattedMessage id={this.props.labelTitle} />
            </h4>
            <ControlLabel>{this.props.labelValue}</ControlLabel>
            {this.inputField()}
            {this.confirmationField()}
            <StyledHelpBlock>{this.state.errorMessage}</StyledHelpBlock>
            <Button bsStyle="primary" onClick={this.props.disableEdit}>
              <FormattedMessage id="general.cancel" />
            </Button>
            <Button bsStyle="default" type="submit">
              <FormattedMessage id="general.update" />
            </Button>
          </FormGroup>
        </form>
      </StyledInputEnabled>
    );
  }
}

InputEnabled.propTypes = {
  inputType: string.isRequired,
  labelValue: string.isRequired,
  inputValue: string.isRequired,
  disableEdit: func.isRequired,
  reloadInfo: func.isRequired,
  labelTitle: string.isRequired,
  dataField: string.isRequired
};

export default InputEnabled;
