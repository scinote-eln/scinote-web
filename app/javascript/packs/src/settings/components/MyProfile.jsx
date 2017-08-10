import React, { Component } from "react";
import axios from "axios";
import _ from "lodash";

import Avatar from "./Avatar";
import InputDisabled from "./InputDisabled";
import InputEnabled from "./InputEnabled";

import { CURRENT_USER_PATH } from "../../../app/routes";

class MyProfile extends Component {
  constructor(props) {
    super(props);

    this.state = {
      avatar: "",
      inputs: {
        fullName: {
          label: "Full name",
          value: "",
          isEditable: false
        }
      }
    };

    this.toggleIsEditable = this.toggleIsEditable.bind(this);
  }

  componentDidMount() {
    axios.get(CURRENT_USER_PATH, { withCredentials: true }).then(data => {
      const userData = data.data.user;
      this.setState(previousState =>
        _.merge({}, previousState, {
          avatar: userData.avatarThumbPath,
          inputs: {
            fullName: {
              value: userData.fullName
            }
          }
        })
      );
    });
  }

  toggleIsEditable(e) {
    const currEditableState = this.state.inputs.fullName.isEditable;
    e.preventDefault();
    this.setState(previousState =>
      _.merge({}, previousState, {
        inputs: { fullName: { isEditable: !currEditableState } }
      })
    );
  }

  render() {
    let fullNameField;
    const fullNameState = this.state.inputs.fullName;

    if (this.state.inputs.fullName.isEditable) {
      fullNameField = (
        <InputEnabled
          labelValue={fullNameState.label}
          inputValue={fullNameState.value}
          inputType="text"
          disableEdit={this.toggleIsEditable}
        />
      );
    } else {
      fullNameField = (
        <InputDisabled
          labelValue={fullNameState.label}
          inputValue={fullNameState.value}
          inputType="text"
          enableEdit={this.toggleIsEditable}
        />
      );
    }

    return (
      <div>
        <h2>My Profile</h2>
        <h4>Avatar</h4>
        <Avatar imgSource={this.state.avatar} />
        {fullNameField}
      </div>
    );
  }
}

export default MyProfile;
