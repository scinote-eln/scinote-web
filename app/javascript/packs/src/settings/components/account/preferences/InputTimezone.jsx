import React, { Component } from "react";
import PropType from "prop-types";
import { Button } from "react-bootstrap";
import styled from "styled-components";
import TimezonePicker from "react-bootstrap-timezone-picker";
import "react-bootstrap-timezone-picker/dist/react-bootstrap-timezone-picker.min.css";
import { FormattedMessage } from "react-intl";

import {
  BORDER_LIGHT_COLOR,
  PRIMARY_GREEN_COLOR,
  PRIMARY_HOVER_COLOR
} from "../../../../../app/constants/colors";

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

  .btn-primary {
    background-color: ${PRIMARY_GREEN_COLOR};
    border-color: ${PRIMARY_HOVER_COLOR};
    margin-right: 7px;
    &:hover {
      background-color: ${PRIMARY_HOVER_COLOR};
    }
  }
`;

class InputTimezone extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: props.inputValue
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleUpdate = this.handleUpdate.bind(this);
  }

  handleChange(timezone) {
    this.setState({ value: timezone });
  }

  handleUpdate() {
    if (this.state.value !== "") {
      this.props.saveData(this.state.value);
    }
    this.props.disableEdit();
  }
  render() {
    return (
      <Wrapper>
        <h4>
          {this.props.labelValue}
        </h4>
        <TimezonePicker
          absolute={false}
          defaultValue="Europe/London"
          value={this.props.inputValue}
          placeholder="Select timezone..."
          onChange={this.handleChange}
          className="time-zone-container"
        />
        <div className="settings-warning">
          <small>
            <FormattedMessage id="settings_page.time_zone_warning" />
          </small>
        </div>
        <Button bsStyle="primary" onClick={this.props.disableEdit}>
          Cancel
        </Button>
        <Button bsStyle="default" onClick={this.handleUpdate}>
          Update
        </Button>
      </Wrapper>
    );
  }
}

InputTimezone.propTypes = {
  labelValue: PropType.string.isRequired,
  inputValue: PropType.string.isRequired,
  disableEdit: PropType.func.isRequired,
  saveData: PropType.func.isRequired
};

export default InputTimezone;
