import React, { Component } from "react";
import PropTypes, { string } from "prop-types";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import {
  WHITE_COLOR,
  DARK_GRAY_COLOR
} from "../../../../../config/constants/colors";

import InputEnabled from "../../../components/InputEnabled";

const AvatarWrapper = styled.div`
  width: 100px;
  height: 100px;
  position: relative;
  cursor: pointer;
`;
const EditAvatar = styled.span`
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
    this.state = { disabled: true };
    this.enableEdit = this.enableEdit.bind(this);
  }

  enableEdit() {
    this.setState({ disabled: false });
  }

  render() {
    if (this.state.disabled) {
      return (
        <AvatarWrapper onClick={this.props.enableEdit}>
          <img src={this.props.imgSource} alt="default avatar" />
          <EditAvatar className="text-center">
            <span className="glyphicon glyphicon-pencil" />
            <FormattedMessage id="settings_page.edit_avatar" />
          </EditAvatar>
        </AvatarWrapper>
      );
    }
    return (
      <InputEnabled
        labelTitle="settings_page.avatar"
        labelValue="Avatar"
        inputType="file"
        inputValue=""
      />
    );
  }
}

AvatarInputField.propTypes = {
  imgSource: string.isRequired,
  enableEdit: PropTypes.func.isRequired
};

export default AvatarInputField;
