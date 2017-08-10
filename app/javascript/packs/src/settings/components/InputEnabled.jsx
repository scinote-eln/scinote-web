import React, { Component } from "react";
import PropTypes from "prop-types";
import { FormGroup, FormControl, ControlLabel, Button } from "react-bootstrap";

class InputEnabled extends Component {
  constructor(props) {
    super(props);

    this.state = {
      value: this.props.inputValue
    };

    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    this.setState({ value: event.target.value });
  }

  render() {
    return (
      <div>
        <form>
          <FormGroup>
            <ControlLabel>
              {this.props.labelValue}
            </ControlLabel>
            <FormControl
              type={this.props.inputType}
              value={this.state.value}
              onChange={this.handleChange}
            />
            <Button bsStyle="primary" onClick={this.props.disableEdit}>
              Cancel
            </Button>
            <Button bsStyle="default">Update</Button>
          </FormGroup>
        </form>
      </div>
    );
  }
}

InputEnabled.propTypes = {
  labelValue: PropTypes.string.isRequired,
  inputType: PropTypes.string.isRequired,
  inputValue: PropTypes.string.isRequired,
  disableEdit: PropTypes.func.isRequired
};

export default InputEnabled;
