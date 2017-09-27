import React, { Component } from "react";
import { string, func } from "prop-types";
import { Button } from "react-bootstrap";
import styled from "styled-components";
import TimezonePicker from "react-bootstrap-timezone-picker";
import "react-bootstrap-timezone-picker/dist/react-bootstrap-timezone-picker.min.css";
import { FormattedMessage } from "react-intl";

import { updateUser } from "../../../../../services/api/users_api";
import InputDisabled from "../../../components/InputDisabled";
import { BORDER_LIGHT_COLOR } from "../../../../../config/constants/colors";

const Wrapper = styled.div`
  border: 1px solid ${BORDER_LIGHT_COLOR};
  padding: 19px;
  margin: 20px 0;

  input {
    margin-bottom: 3px;
  }

  .settings-warning {
    margin-bottom: 15px;
  }
`;

const WrapperInputDisabled = styled.div`
  margin: 20px 0;
  padding-bottom: 15px;
  border-bottom: 1px solid ${BORDER_LIGHT_COLOR};

  .settings-warning {
    margin-top: -5px;
  }
`;

class InputTimezone extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: "",
      disabled: true
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleUpdate = this.handleUpdate.bind(this);
    this.enableEdit = this.enableEdit.bind(this);
    this.disableEdit = this.disableEdit.bind(this);
  }

  handleChange(timezone) {
    this.setState({ value: timezone });
  }

  handleUpdate() {
    if (this.state.value !== "") {
      updateUser({ time_zone: this.state.value }).then(() => {
        this.disableEdit();
      });
    }
  }

  enableEdit() {
    this.setState({ disabled: false, value: this.props.value });
  }

  disableEdit() {
    this.setState({ disabled: true });
    this.props.loadPreferences();
  }

  render() {
    if (this.state.disabled) {
      return (
        <WrapperInputDisabled>
          <InputDisabled
            labelTitle="settings_page.time_zone"
            inputValue={this.props.value}
            inputType="text"
            enableEdit={this.enableEdit}
          />
          <div className="settings-warning">
            <small>
              <FormattedMessage id="settings_page.time_zone_warning" />
            </small>
          </div>
        </WrapperInputDisabled>
      );
    }

    return (
      <Wrapper>
        <h4>
          <FormattedMessage id="settings_page.time_zone" />
        </h4>
        <TimezonePicker
          absolute
          defaultValue="Europe/London"
          value={this.state.value}
          placeholder="Select timezone..."
          onChange={this.handleChange}
        />
        <div className="settings-warning">
          <small>
            <FormattedMessage id="settings_page.time_zone_warning" />
          </small>
        </div>
        <Button bsStyle="primary" onClick={this.disableEdit}>
          <FormattedMessage id="general.cancel" />
        </Button>
        <Button bsStyle="default" onClick={this.handleUpdate}>
          <FormattedMessage id="general.update" />
        </Button>
      </Wrapper>
    );
  }
}

InputTimezone.propTypes = {
  value: string.isRequired,
  loadPreferences: func.isRequired
};

export default InputTimezone;
