import React, { Component } from "react";
import { string, func } from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import {
  WHITE_COLOR,
  DARK_GRAY_COLOR
} from "../../../../../config/constants/colors";

import InputEnabled from "./InputEnabled";

const AvatarWrapper = styled.div`
  width: 100px;
  height: 100px;
  position: relative;
  cursor: pointer;
  &:hover > span {
    display: block;
  }
`;

const EditAvatar = styled.span`
  display: none;
  color: ${WHITE_COLOR};
  background-color: ${DARK_GRAY_COLOR};
  position: absolute;
  left: 0;
  bottom: 0;
  width: 100%;
  opacity: 0.7;
  padding: 5px;
`;

class AvatarInputField extends Component {
  constructor(props) {
    super(props);
    this.state = { disabled: true, timestamp: "" };
    this.enableEdit = this.enableEdit.bind(this);
    this.disableEdit = this.disableEdit.bind(this);
    this.rerender = this.rerender.bind(this);
  }

  enableEdit() {
    this.setState({ disabled: false });
  }

  disableEdit() {
    this.setState({ disabled: true });
  }

  rerender() {
    this.setState({ timestamp: `?${new Date().getTime()}` });
  }

  render() {
    if (this.state.disabled) {
      return (
        <AvatarWrapper onClick={this.enableEdit} className="avatar-container">
          <img
            src={this.props.imgSource + this.state.timestamp}
            alt="default avatar"
          />
          <EditAvatar className="text-center">
            <span className="fas fa-pencil-alt" />
            <FormattedMessage id="settings_page.edit_avatar" />
          </EditAvatar>
        </AvatarWrapper>
      );
    }
    return (
      <InputEnabled
        forceRerender={this.rerender}
        labelTitle="settings_page.avatar"
        labelValue="settings_page.upload_new_avatar"
        inputType="file"
        inputValue=""
        dataField="avatar"
        disableEdit={this.disableEdit}
        reloadInfo={this.props.reloadInfo}
      />
    );
  }
}

AvatarInputField.propTypes = {
  imgSource: string.isRequired,
  reloadInfo: func.isRequired
};

export default AvatarInputField;
