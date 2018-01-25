import React, { Component } from "react";
import { string, func } from "prop-types";

import InputDisabled from "../../../components/InputDisabled";
import InputEnabled from "./InputEnabled";

class ProfileInputField extends Component {
  constructor(props) {
    super(props);
    this.state = { disabled: true };
    this.toggleSate = this.toggleSate.bind(this);
  }

  toggleSate() {
    this.setState({ disabled: !this.state.disabled });
  }

  render() {
    if (this.state.disabled) {
      return (
        <InputDisabled
          labelTitle={this.props.labelTitle}
          inputValue={this.props.value}
          inputType={this.props.inputType}
          enableEdit={this.toggleSate}
        />
      );
    }
    return (
      <InputEnabled
        labelTitle={this.props.labelTitle}
        labelValue={this.props.labelValue}
        inputType={this.props.inputType}
        inputValue={this.props.value}
        disableEdit={this.toggleSate}
        reloadInfo={this.props.reloadInfo}
        dataField={this.props.dataField}
      />
    );
  }
}

ProfileInputField.propTypes = {
  value: string.isRequired,
  inputType: string.isRequired,
  labelTitle: string.isRequired,
  labelValue: string.isRequired,
  dataField: string.isRequired,
  reloadInfo: func.isRequired
};

export default ProfileInputField;
