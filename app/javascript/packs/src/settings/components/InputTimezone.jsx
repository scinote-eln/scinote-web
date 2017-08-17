import React, { Component } from "react";
import PropType from "prop-types";
import { Button } from "react-bootstrap";
import TimezonePicker from "react-bootstrap-timezone-picker";
import "react-bootstrap-timezone-picker/dist/react-bootstrap-timezone-picker.min.css";

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
      <div>
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
        <Button bsStyle="primary" onClick={this.props.disableEdit}>
          Cancel
        </Button>
        <Button bsStyle="default" onClick={this.handleUpdate}>
          Update
        </Button>
      </div>
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
