import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";

import Avatar from "./Avatar";
import InputDisabled from "./InputDisabled";
import InputEnabled from "./InputEnabled";

import {
  changeFullName,
  changeInitials,
  changeEmail,
  changePassword,
  changeAvatar
} from "../../../shared/actions/UsersActions";

class MyProfile extends Component {
  constructor(props) {
    super(props);

    this.state = {
      isFullNameEditable: false,
      areInitialsEditable: false,
      isEmailEditable: false,
      isPasswordEditable: false,
      isAvatarEditable: false
    };

    this.toggleIsEditable = this.toggleIsEditable.bind(this);
  }

  toggleIsEditable(fieldNameEnabled) {
    const editableState = this.state[fieldNameEnabled];
    this.setState({ [fieldNameEnabled]: !editableState });
  }

  render() {
    const areInitialsEditable = "areInitialsEditable";
    const isFullNameEditable = "isFullNameEditable";
    const isEmailEditable = "isEmailEditable";
    const isPasswordEditable = "isPasswordEditable";
    const isAvatarEditable = "isAvatarEditable";
    let fullNameField;
    let initialsField;
    let emailField;
    let passwordField;
    let avatarField;

    if (this.state.isAvatarEditable) {
      avatarField = (
        <InputEnabled
          labelValue="Avatar"
          inputType="file"
          inputValue=""
          disableEdit={() => this.toggleIsEditable(isAvatarEditable)}
          saveData={avatarSrc => this.props.changeAvatar(avatarSrc)}
        />
      );
    } else {
      avatarField = (
        <Avatar
          imgSource={this.props.avatarThumbPath}
          enableEdit={() => this.toggleIsEditable(isAvatarEditable)}
        />
      );
    }

    if (this.state.isPasswordEditable) {
      passwordField = (
        <InputEnabled
          labelValue="Change password"
          inputType="password"
          inputValue=""
          disableEdit={() => this.toggleIsEditable(isPasswordEditable)}
          saveData={newPassword => this.props.changePassword(newPassword)}
        />
      );
    } else {
      passwordField = (
        <InputDisabled
          labelValue="Change password"
          inputType="password"
          inputValue=""
          enableEdit={() => this.toggleIsEditable(isPasswordEditable)}
        />
      );
    }

    if (this.state.isEmailEditable) {
      emailField = (
        <InputEnabled
          labelValue="New email"
          inputType="email"
          inputValue={this.props.email}
          disableEdit={() => this.toggleIsEditable(isEmailEditable)}
          saveData={newEmail => this.props.changeEmail(newEmail)}
        />
      );
    } else {
      emailField = (
        <InputDisabled
          labelValue="New email"
          inputValue={this.props.email}
          inputType="email"
          enableEdit={() => this.toggleIsEditable(isEmailEditable)}
        />
      );
    }

    if (this.state.areInitialsEditable) {
      initialsField = (
        <InputEnabled
          labelValue="Initials"
          inputType="text"
          inputValue={this.props.initials}
          disableEdit={() => this.toggleIsEditable(areInitialsEditable)}
          saveData={newName => this.props.changeInitials(newName)}
        />
      );
    } else {
      initialsField = (
        <InputDisabled
          labelValue="Initials"
          inputValue={this.props.initials}
          inputType="text"
          enableEdit={() => this.toggleIsEditable(areInitialsEditable)}
        />
      );
    }

    if (this.state.isFullNameEditable) {
      fullNameField = (
        <InputEnabled
          labelValue="Full name"
          inputType="text"
          inputValue={this.props.fullName}
          disableEdit={() => this.toggleIsEditable(isFullNameEditable)}
          saveData={newName => this.props.changeFullName(newName)}
        />
      );
    } else {
      fullNameField = (
        <InputDisabled
          labelValue="Full name"
          inputValue={this.props.fullName}
          inputType="text"
          enableEdit={() => this.toggleIsEditable(isFullNameEditable)}
        />
      );
    }

    return (
      <div>
        <h2>My Profile</h2>
        <h4>Avatar</h4>
        {avatarField}
        {fullNameField}
        {initialsField}
        {emailField}
        {passwordField}
      </div>
    );
  }
}

MyProfile.propTypes = {
  fullName: PropTypes.string.isRequired,
  avatarThumbPath: PropTypes.string.isRequired,
  initials: PropTypes.string.isRequired,
  email: PropTypes.string.isRequired,
  changeFullName: PropTypes.func.isRequired,
  changeInitials: PropTypes.func.isRequired,
  changeEmail: PropTypes.func.isRequired,
  changePassword: PropTypes.func.isRequired,
  changeAvatar: PropTypes.func.isRequired
};

const mapStateToProps = state => state.current_user;
const mapDispatchToProps = dispatch => ({
  changeFullName(name) {
    dispatch(changeFullName(name));
  },
  changeInitials(initials) {
    dispatch(changeInitials(initials));
  },
  changeEmail(email) {
    dispatch(changeEmail(email));
  },
  changePassword(password) {
    dispatch(changePassword(password));
  },
  changeAvatar(avatarSrc) {
    dispatch(changeAvatar(avatarSrc));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(MyProfile);
