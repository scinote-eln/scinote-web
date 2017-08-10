import React from "react";
import { string } from "prop-types";

const Avatar = props => <img src={props.imgSource} alt="default avatar" />;

Avatar.propTypes = {
  imgSource: string.isRequired
};

export default Avatar;
