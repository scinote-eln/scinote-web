import React from "react";
import PropTypes, { string } from "prop-types";
import styled from "styled-components";

const AvatarWrapper = styled.div`
  width: 100px;
  height: 100px;
  position: relative;
`;
const EditAvatar = styled.span`
  position: absolute;
  left: 0;
  bottom: 0;
  width: 100%;
  background-color: silver;
`;

const Avatar = props =>
  <AvatarWrapper onClick={props.enableEdit}>
    <img src={props.imgSource} alt="default avatar" />
    <EditAvatar>Edit Avatar</EditAvatar>
  </AvatarWrapper>;

Avatar.propTypes = {
  imgSource: string.isRequired,
  enableEdit: PropTypes.func.isRequired
};

export default Avatar;
