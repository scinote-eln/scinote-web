import React from "react";
import styled from "styled-components";
import PropTypes from "prop-types";

import { MAIN_COLOR_BLUE } from "../../../app/constants/colors";

const Box = styled.div`
  width: 100px;
  height: 100px;
  color: #fff;
  background-color: ${MAIN_COLOR_BLUE};
  display: inline-block;
  margin: 15px;
  text-align: center;
  border-radius: 0.25em;
`;

const MyStatisticsBox = props =>
  <Box>
    <h2>
      {props.typeLength}
    </h2>
    <h5>
      {props.typeText}
    </h5>
  </Box>;

MyStatisticsBox.propTypes = {
  typeLength: PropTypes.number.isRequired,
  typeText: PropTypes.string.isRequired
};

export default MyStatisticsBox;
