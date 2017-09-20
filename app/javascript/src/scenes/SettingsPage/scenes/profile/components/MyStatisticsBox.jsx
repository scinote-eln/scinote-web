import React from "react";
import styled from "styled-components";
import PropTypes from "prop-types";
import { FormattedMessage } from "react-intl";

import { MAIN_COLOR_BLUE } from "../../../../../config/constants/colors";

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
      {props.typeLength === 1
        ? <FormattedMessage id={props.singular} />
        : <FormattedMessage id={props.plural} />}
    </h5>
  </Box>;

MyStatisticsBox.defaultProps = {
  typeLength: 0
};

MyStatisticsBox.propTypes = {
  typeLength: PropTypes.number.isRequired,
  plural: PropTypes.string.isRequired,
  singular: PropTypes.string.isRequired
};

export default MyStatisticsBox;
