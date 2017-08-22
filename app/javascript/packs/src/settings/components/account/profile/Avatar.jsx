import React from "react";
import PropTypes, { string } from "prop-types";
import styled from "styled-components";

import {
  WHITE_COLOR,
  DARK_GRAY_COLOR
} from "../../../../../app/constants/colors";

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

const Avatar = props =>
  <AvatarWrapper onClick={props.enableEdit}>
    <img src={props.imgSource} alt="default avatar" />
    <EditAvatar className="text-center">
      <span className="glyphicon glyphicon-pencil" /> Edit Avatar
    </EditAvatar>
  </AvatarWrapper>;

Avatar.propTypes = {
  imgSource: string.isRequired,
  enableEdit: PropTypes.func.isRequired
};

export default Avatar;
