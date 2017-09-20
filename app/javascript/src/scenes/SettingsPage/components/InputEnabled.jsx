import React, { Component } from "react";
import PropTypes from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";
import { FormGroup, FormControl, ControlLabel, Button } from "react-bootstrap";

import { BORDER_LIGHT_COLOR } from "../../../config/constants/colors";
import { ENTER_KEY_CODE } from "../../../config/constants/numeric";

const StyledInputEnabled = styled.div`
  border: 1px solid ${BORDER_LIGHT_COLOR};
  padding: 19px;
  margin: 20px 0;

  input {
    margin-bottom: 15px;
  }
`;

const ErrorMsg = styled.div`color: red;`;

class InputEnabled extends Component {
  constructor(props) {
    super(props);

    if (props.inputType === "password") {
      this.state = {
        value: "",
        value2: ""
      };
    } else {
      this.state = {
        value: this.props.inputValue
      };
    }

    this.handleChange = this.handleChange.bind(this);
    this.handleChange2 = this.handleChange2.bind(this);
    this.handleUpdate = this.handleUpdate.bind(this);
    this.handleKeyPress = this.handleKeyPress.bind(this);
  }

  handleKeyPress(event) {
    if (event.charCode === ENTER_KEY_CODE) {
      event.preventDefault();
      this.handleUpdate();
    }
  }

  handleChange(event) {
    this.setState({ value: event.target.value });
  }

  handleChange2(event) {
    this.setState({ value2: event.target.value });
  }

  handleSubmit(event) {
    event.preventDefault();
  }

  handleUpdate() {
    this.props.saveData(this.state.value);
    this.props.disableEdit();
  }

  confirmationField() {
    let inputs;
    const type = this.props.inputType;

    if (type === "email" || type === "password") {
      inputs = (
        <div>
          <p>
            Current password (we need your current password to confirm your
            changes)
          </p>
          <FormControl type="password" />
        </div>
      );
    }

    return inputs;
  }

  errorMsg() {
    return this.state.value !== this.state.value2
      ? <ErrorMsg>Passwords do not match!</ErrorMsg>
      : "";
  }

  inputField() {
    let input;

    if (this.props.inputType === "password") {
      input = (
        <div>
          <FormControl
            type={this.props.inputType}
            value={this.state.value}
            onChange={this.handleChange}
            onKeyPress={this.handleKeyPress}
            autoFocus
          />
          <p>New password confirmation</p>
          <FormControl
            type={this.props.inputType}
            value={this.state.value2}
            onChange={this.handleChange2}
          />
          {this.errorMsg()}
        </div>
      );
    } else {
      input = (
        <FormControl
          type={this.props.inputType}
          value={this.state.value}
          onChange={this.handleChange}
          onKeyPress={this.handleKeyPress}
          autoFocus
        />
      );
    }

    return input;
  }

  render() {
    return (
      <StyledInputEnabled>
        <form onSubmit={this.handleSubmit}>
          <FormGroup>
            <h4>
              <FormattedMessage id="settings_page.change" />{" "}
              <FormattedMessage id={this.props.labelTitle} />
            </h4>
            {this.confirmationField()}
            <ControlLabel>
              {this.props.labelValue}
            </ControlLabel>
            {this.inputField()}
            <Button bsStyle="primary" onClick={this.props.disableEdit}>
              <FormattedMessage id="general.cancel" />
            </Button>
            <Button bsStyle="default" onClick={this.handleUpdate}>
              <FormattedMessage id="general.update" />
            </Button>
          </FormGroup>
        </form>
      </StyledInputEnabled>
    );
  }
}

InputEnabled.propTypes = {
  inputType: PropTypes.string.isRequired,
  labelValue: PropTypes.string.isRequired,
  inputValue: PropTypes.string.isRequired,
  disableEdit: PropTypes.func.isRequired,
  saveData: PropTypes.func.isRequired,
  labelTitle: PropTypes.string.isRequired
};

export default InputEnabled;
