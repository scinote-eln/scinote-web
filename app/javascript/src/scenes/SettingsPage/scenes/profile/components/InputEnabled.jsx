import React, { Component } from "react";
import { connect } from "react-redux";
import { string, func } from "prop-types";
import styled from "styled-components";
import { FormattedMessage, FormattedHTMLMessage } from "react-intl";
import {
  ControlLabel,
  Button,
  ButtonToolbar,
} from "react-bootstrap";
import update from "immutability-helper";
import { transformName } from "../../../../../services/helpers/string_helper";
import { updateUser } from "../../../../../services/api/users_api";
import { addAlert } from "../../../../../components/actions/AlertsActions";

import {
  BORDER_LIGHT_COLOR,
} from "../../../../../config/constants/colors";
import {
  ENTER_KEY_CODE,
} from "../../../../../config/constants/numeric";
import {
  ValidatedForm,
  ValidatedFormGroup,
  ValidatedFormControl,
  ValidatedErrorHelpBlock,
  ValidatedSubmitButton
} from "../../../../../components/validation";
import {
  textBlankValidator,
  nameMaxLengthValidator,
  passwordLengthValidator,
  userInitialsMaxLengthValidator,
  emailValidator
} from "../../../../../components/validation/validators/text";
import {
  avatarExtensionValidator,
  avatarSizeValidator
} from "../../../../../components/validation/validators/file";

const StyledInputEnabled = styled.div`
  border: 1px solid ${BORDER_LIGHT_COLOR};
  padding: 19px;
  margin: 20px 0;

  input {
    margin-bottom: 15px;
  }
`;

class InputEnabled extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: this.props.inputValue === "********" ? "" : this.props.inputValue,
      current_password: "",
      password_confirmation: ""
    };

    this.handleKeyPress = this.handleKeyPress.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.handleCurrentPassword = this.handleCurrentPassword.bind(this);
    this.handlePasswordConfirmation = this.handlePasswordConfirmation.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.inputField = this.inputField.bind(this);
    this.confirmationField = this.confirmationField.bind(this);
  }

  handleKeyPress(event) {
    if (event.charCode === ENTER_KEY_CODE) {
      event.preventDefault();
      this.handleSubmit(event);
    }
  }

  handleChange(event) {
    let newVal;
    if (this.props.dataField === "avatar") {
      newVal = event.currentTarget.files[0];
    } else {
      newVal = event.target.value;
    }
    const newState = update(this.state, {
      value: { $set: newVal }
    });
    this.setState(newState);
  }

  handleCurrentPassword(event) {
    const newState = update(this.state, {
      current_password: { $set: event.target.value }
    });
    this.setState(newState);
  }

  handlePasswordConfirmation(event) {
    const newState = update(this.state, {
      password_confirmation: { $set: event.target.value }
    });
    this.setState(newState);
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
        this.props.addAlert(
          <FormattedMessage id="settings_page.success_update_flash" />,
          "success"
        );
        if (this.props.forceRerender) {
          this.props.forceRerender();
        }
      })
      .catch(({ response }) => {
        this.form.setErrors(response.data.details);
      });
  }

  confirmationField() {
    const type = this.props.inputType;

    if (type === "email") {
      return (
        <ValidatedFormGroup tag="current_password">
          <ControlLabel>
            <FormattedHTMLMessage id="settings_page.password_confirmation" />
          </ControlLabel>
          <ValidatedFormControl
            id="settings_page.current_password"
            tag="current_password"
            type="password"
            value={this.state.current_password}
            validatorsOnChange={[passwordLengthValidator]}
            onChange={this.handleCurrentPassword}
            onKeyPress={this.handleKeyPress}
          />
          <ValidatedErrorHelpBlock tag="current_password" />
        </ValidatedFormGroup>
      );
    }
    return "";
  }

  inputField() {
    const { inputType, dataField } = this.props;

    let validatorsOnChange = [];
    if (dataField === "full_name") {
      validatorsOnChange = [textBlankValidator, nameMaxLengthValidator];
    } else if (dataField === "initials") {
      validatorsOnChange = [textBlankValidator, userInitialsMaxLengthValidator];
    } else if (dataField === "email") {
      validatorsOnChange = [emailValidator];
    } else if (dataField === "avatar") {
      validatorsOnChange = [avatarExtensionValidator, avatarSizeValidator];
    }

    if (inputType === "password") {
      return (
        <div>
          <ValidatedFormGroup tag="current_password">
            <ControlLabel>
              <FormattedHTMLMessage id="settings_page.password_confirmation" />
            </ControlLabel>
            <ValidatedFormControl
              id="settings_page.current_password"
              type="password"
              value={this.state.current_password}
              tag="current_password"
              validatorsOnChange={[passwordLengthValidator]}
              onChange={this.handleCurrentPassword}
              onKeyPress={this.handleKeyPress}
              autoFocus
            />
            <ValidatedErrorHelpBlock tag="current_password" />
          </ValidatedFormGroup>
          <ValidatedFormGroup tag="new_password">
            <ControlLabel>
              <FormattedMessage id="settings_page.new_password" />
            </ControlLabel>
            <ValidatedFormControl
              id="settings_page.new_password"
              type="password"
              value={this.state.value}
              onChange={this.handleChange}
              onKeyPress={this.handleKeyPress}
              tag="new_password"
              validatorsOnChange={[passwordLengthValidator]}
              autoFocus
            />
            <ValidatedErrorHelpBlock tag="new_password" />
          </ValidatedFormGroup>
          <ValidatedFormGroup tag="password_confirmation">
            <ControlLabel>
              <FormattedMessage id="settings_page.new_password_confirmation" />
            </ControlLabel>
            <ValidatedFormControl
              id="settings_page.new_password_confirmation"
              type="password"
              value={this.state.password_confirmation}
              onChange={this.handlePasswordConfirmation}
              onKeyPress={this.handleKeyPress}
              tag="password_confirmation"
              validatorsOnChange={[passwordLengthValidator]}
            />
            <ValidatedErrorHelpBlock tag="password_confirmation" />
          </ValidatedFormGroup>
        </div>
      );
    }
    if (inputType === "file") {
      return (
        <ValidatedFormGroup tag={dataField}>
          <ValidatedFormControl
            id="user_avatar_input"
            tag={dataField}
            type={this.props.inputType}
            onChange={this.handleChange}
            onKeyPress={this.handleKeyPress}
            validatorsOnChange={validatorsOnChange}
            autoFocus
          />
          <ValidatedErrorHelpBlock tag={dataField} />
        </ValidatedFormGroup>
      );
    }
    return (
      <ValidatedFormGroup tag={dataField}>
        <ValidatedFormControl
          id={transformName(this.props.labelTitle)}
          tag={dataField}
          type={this.props.inputType}
          onChange={this.handleChange}
          onKeyPress={this.handleKeyPress}
          validatorsOnChange={validatorsOnChange}
          value={this.state.value}
          autoFocus
        />
        <ValidatedErrorHelpBlock tag={dataField} />
      </ValidatedFormGroup>
    );
  }

  render() {
    return (
      <StyledInputEnabled>
        <ValidatedForm
          onSubmit={this.handleSubmit}
          ref={(f) => { this.form = f; }}
        >
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
          <ButtonToolbar>
            <ValidatedSubmitButton bsStyle="primary" type="submit">
              <FormattedMessage
                id={`general.${this.props.dataField === "avatar"
                  ? "upload"
                  : "update"}`}
              />
            </ValidatedSubmitButton>
            <Button bsStyle="default" onClick={this.props.disableEdit}>
              <FormattedMessage id="general.cancel" />
            </Button>
          </ButtonToolbar>
        </ValidatedForm>
      </StyledInputEnabled>
    );
  }
}

InputEnabled.propTypes = {
  addAlert: func.isRequired,
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

export default connect(null, { addAlert })(InputEnabled);
