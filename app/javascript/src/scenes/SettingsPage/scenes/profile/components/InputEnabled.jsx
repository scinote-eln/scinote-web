import React, { Component } from "react";
import { string, func } from "prop-types";
import styled from "styled-components";
import { FormattedMessage, FormattedHTMLMessage } from "react-intl";
import {
  FormGroup,
  FormControl,
  ControlLabel,
  Button,
  ButtonToolbar,
  HelpBlock
} from "react-bootstrap";
import { updateUser } from "../../../../../services/api/users_api";

import {
  BORDER_LIGHT_COLOR,
  COLOR_APPLE_BLOSSOM
} from "../../../../../config/constants/colors";
import {
  ENTER_KEY_CODE,
  USER_INITIALS_MAX_LENGTH,
  NAME_MAX_LENGTH,
  PASSWORD_MAX_LENGTH,
  PASSWORD_MIN_LENGTH
} from "../../../../../config/constants/numeric";
import { EMAIL_REGEX } from "../../../../../config/constants/strings";

const StyledInputEnabled = styled.div`
  border: 1px solid ${BORDER_LIGHT_COLOR};
  padding: 19px;
  margin: 20px 0;

  input {
    margin-bottom: 15px;
  }
`;

const StyledHelpBlock = styled(HelpBlock)`
  color: ${COLOR_APPLE_BLOSSOM};
`;

class InputEnabled extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: this.props.inputValue === "********" ? "" : this.props.inputValue,
      current_password: "",
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
    this.handleCurrentPassword = this.handleCurrentPassword.bind(this);
    this.handleFileChange = this.handleFileChange.bind(this);
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
    event.preventDefault();
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
      case "avatar":
        this.handleFileChange(event);
        break;
      default:
        this.setState({ value: event.target.value, errorMessage: "" });
    }
  }

  handleFileChange(event) {
    this.setState({ value: event.currentTarget.files[0], errorMessage: "" });
  }

  handlePasswordConfirmation(event) {
    const { value } = event.target;
    if (value.length === 0) {
      this.setState({
        password_confirmation: value,
        errorMessage: <FormattedMessage id="error_messages.cant_be_blank" />
      });
    }
    this.setState({ password_confirmation: value });
  }

  handleFullNameValidation(event) {
    const { value } = event.target;
    if (value.length > NAME_MAX_LENGTH) {
      this.setState({
        value,
        errorMessage: (
          <FormattedMessage
            id="error_messages.text_too_long"
            values={{ max_length: NAME_MAX_LENGTH }}
          />
        )
      });
    } else if (value.length === 0) {
      this.setState({
        value,
        errorMessage: <FormattedMessage id="error_messages.cant_be_blank" />
      });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handleEmailValidation(event) {
    const { value } = event.target;
    if (!EMAIL_REGEX.test(value)) {
      this.setState({
        value,
        errorMessage: <FormattedMessage id="error_messages.invalid_email" />
      });
    } else if (value.length === 0) {
      this.setState({
        value,
        errorMessage: <FormattedMessage id="error_messages.cant_be_blank" />
      });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handleInitialsValidation(event) {
    const { value } = event.target;
    if (value.length > USER_INITIALS_MAX_LENGTH) {
      this.setState({
        value,
        errorMessage: (
          <FormattedMessage
            id="error_messages.text_too_long"
            values={{ max_length: USER_INITIALS_MAX_LENGTH }}
          />
        )
      });
    } else if (value.length === 0) {
      this.setState({
        value,
        errorMessage: <FormattedMessage id="error_messages.cant_be_blank" />
      });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handlePasswordValidation(event) {
    const { value } = event.target;
    if (value.length > PASSWORD_MAX_LENGTH) {
      this.setState({
        value,
        errorMessage: (
          <FormattedMessage
            id="error_messages.text_too_long"
            values={{ max_length: PASSWORD_MAX_LENGTH }}
          />
        )
      });
    } else if (value.length < PASSWORD_MIN_LENGTH) {
      this.setState({
        value,
        errorMessage: (
          <FormattedMessage
            id="error_messages.text_too_short"
            values={{ min_length: PASSWORD_MIN_LENGTH }}
          />
        )
      });
    } else {
      this.setState({ value, errorMessage: "" });
    }
  }

  handlePasswordConfirmationValidation(event) {
    const { value } = event.target;
    if (value !== this.state.value) {
      this.setState({
        password_confirmation: value,
        errorMessage: (
          <FormattedMessage id="error_messages.passwords_dont_match" />
        )
      });
    } else {
      this.setState({ password_confirmation: value, errorMessage: "" });
    }
  }

  handleCurrentPassword(event) {
    const { value } = event.target;
    if (value.length > PASSWORD_MAX_LENGTH) {
      this.setState({
        current_password: value,
        errorMessage: (
          <FormattedMessage
            id="error_messages.text_too_long"
            values={{ max_length: PASSWORD_MAX_LENGTH }}
          />
        )
      });
    } else if (value.length < PASSWORD_MIN_LENGTH) {
      this.setState({
        current_password: value,
        errorMessage: (
          <FormattedMessage
            id="error_messages.text_too_short"
            values={{ min_length: PASSWORD_MIN_LENGTH }}
          />
        )
      });
    } else {
      this.setState({ current_password: value, errorMessage: "" });
    }
  }

  handleSubmit(event) {
    event.preventDefault();
    const { dataField } = this.props;
    let params;
    let formObj;
    let formData;
    switch (dataField) {
      case "email":
        params = {
          [dataField]: this.state.value,
          current_password: this.state.current_password
        };
        break;
      case "password":
        params = {
          [dataField]: this.state.value,
          current_password: this.state.current_password,
          password_confirmation: this.state.password_confirmation
        };
        break;
      case "avatar":
        formData = new FormData();
        formData.append("user[avatar]", this.state.value);
        formObj = true;
        params = formData;
        break;
      default:
        params = { [dataField]: this.state.value };
    }

    updateUser(params, formObj)
      .then(() => {
        this.props.reloadInfo();
        this.props.disableEdit();
        if (this.props.forceRerender) {
          this.props.forceRerender();
        }
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
          <FormattedHTMLMessage id="settings_page.password_confirmation" />
          <FormControl
            type="password"
            value={this.state.current_password}
            onChange={this.handleCurrentPassword}
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
          <FormattedHTMLMessage id="settings_page.password_confirmation" />
          <FormControl
            type={inputType}
            value={this.state.current_password}
            onChange={this.handleCurrentPassword}
            autoFocus
          />
          <ControlLabel>
            <FormattedMessage id="settings_page.new_password" />
          </ControlLabel>
          <FormControl
            type={inputType}
            value={this.state.value}
            onChange={this.handleChange}
            autoFocus
          />
          <ControlLabel>
            <FormattedMessage id="settings_page.new_password_confirmation" />
          </ControlLabel>
          <FormControl
            type={inputType}
            value={this.state.password_confirmation}
            onChange={this.handlePasswordConfirmationValidation}
          />
        </div>
      );
    }
    if (inputType === "file") {
      return (
        <FormControl
          type={this.props.inputType}
          onChange={this.handleChange}
          onKeyPress={this.handleKeyPress}
          autoFocus
        />
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
              <FormattedMessage id="settings_page.change" />&nbsp;
              <FormattedMessage id={this.props.labelTitle} />
            </h4>
            {this.props.labelValue !== "none" && (
              <ControlLabel>
                <FormattedMessage id={this.props.labelValue} />
              </ControlLabel>
            )}
            {this.inputField()}
            {this.confirmationField()}
            <StyledHelpBlock>{this.state.errorMessage}</StyledHelpBlock>
            <ButtonToolbar>
              <Button bsStyle="primary" type="submit">
                <FormattedMessage
                  id={`general.${this.props.dataField === "avatar"
                    ? "upload"
                    : "update"}`}
                />
              </Button>
              <Button bsStyle="default" onClick={this.props.disableEdit}>
                <FormattedMessage id="general.cancel" />
              </Button>
            </ButtonToolbar>
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
  dataField: string.isRequired,
  forceRerender: func
};

InputEnabled.defaultProps = {
  forceRerender: () => false
};

export default InputEnabled;
