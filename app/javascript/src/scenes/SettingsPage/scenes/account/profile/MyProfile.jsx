import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import axios from "../../../../../config/axios";
import Avatar from "./Avatar";
import InputDisabled from "../InputDisabled";
import InputEnabled from "../InputEnabled";

import {
  changeFullName,
  changeInitials,
  changeEmail,
  changePassword,
  changeAvatar
} from "../../../../../components/actions/UsersActions";

const AvatarLabel = styled.h4`
  margin-top: 15px;
  font-size: 13px;
  font-weight: 700;
`;

class MyProfile extends Component {
  constructor(props) {
    super(props);

    this.state = {
      fullName: "",
      avatarThumb: "",
      initials: "",
      email: "",
      timeZone: "",
      newEmail: "",
      isFullNameEditable: false,
      areInitialsEditable: false,
      isEmailEditable: false,
      isPasswordEditable: false,
      isAvatarEditable: false
    };

    this.toggleIsEditable = this.toggleIsEditable.bind(this);
    this.getProfileInfo = this.getProfileInfo.bind(this);
    this.setData = this.setData.bind(this);
  }

  componentDidMount() {
    this.getProfileInfo();
  }

  setData({ data }) {
    const user = data.user;

    // TODO move this transformation to seperate method

    const newData = {
      fullName: user.full_name,
      initials: user.initials,
      email: user.email,
      avatarThumb: user.avatar_thumb_path,
      timeZone: user.time_zone
    };

    this.setState(Object.assign({}, this.state, newData));
  }

  getProfileInfo() {
    axios
      .get("/client_api/users/profile_info")
      .then(response => this.setData(response))
      .catch(error => console.log(error));
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
          labelTitle="settings_page.avatar"
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
          imgSource={this.state.avatarThumb}
          enableEdit={() => this.toggleIsEditable(isAvatarEditable)}
        />
      );
    }

    if (this.state.isPasswordEditable) {
      passwordField = (
        <InputEnabled
          labelTitle="settings_page.change_password"
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
          labelTitle="settings_page.change_password"
          inputType="password"
          inputValue=""
          enableEdit={() => this.toggleIsEditable(isPasswordEditable)}
        />
      );
    }

    if (this.state.isEmailEditable) {
      emailField = (
        <InputEnabled
          labelTitle="settings_page.new_email"
          labelValue="New email"
          inputType="email"
          inputValue={this.state.email}
          disableEdit={() => this.toggleIsEditable(isEmailEditable)}
          saveData={newEmail => this.props.changeEmail(newEmail)}
        />
      );
    } else {
      emailField = (
        <InputDisabled
          labelTitle="settings_page.new_email"
          inputValue={this.state.email}
          inputType="email"
          enableEdit={() => this.toggleIsEditable(isEmailEditable)}
        />
      );
    }

    if (this.state.areInitialsEditable) {
      initialsField = (
        <InputEnabled
          labelTitle="settings_page.initials"
          labelValue="Initials"
          inputType="text"
          inputValue={this.state.initials}
          disableEdit={() => this.toggleIsEditable(areInitialsEditable)}
          saveData={newName => this.props.changeInitials(newName)}
        />
      );
    } else {
      initialsField = (
        <InputDisabled
          labelTitle="settings_page.initials"
          inputValue={this.state.initials}
          inputType="text"
          enableEdit={() => this.toggleIsEditable(areInitialsEditable)}
        />
      );
    }

    if (this.state.isFullNameEditable) {
      fullNameField = (
        <InputEnabled
          labelTitle="settings_page.full_name"
          labelValue="Full name"
          inputType="text"
          inputValue={this.state.fullName}
          disableEdit={() => this.toggleIsEditable(isFullNameEditable)}
          saveData={newName => this.props.changeFullName(newName)}
        />
      );
    } else {
      fullNameField = (
        <InputDisabled
          labelTitle="settings_page.full_name"
          inputValue={this.state.fullName}
          inputType="text"
          enableEdit={() => this.toggleIsEditable(isFullNameEditable)}
        />
      );
    }

    return (
      <div>
        <h2>
          <FormattedMessage id="settings_page.my_profile" />
        </h2>
        <AvatarLabel>
          <FormattedMessage id="settings_page.avatar" />
        </AvatarLabel>
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
