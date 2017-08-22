import React from "react";
import PropTypes from "prop-types";
import Moment from "react-moment";
import styled from "styled-components";

import { WHITE_COLOR } from "../../../app/constants/colors"

const StyledLi = styled.li`
  margin-bottom: 1em;
`

const StyledSpan = styled.span`
  display: inline;
  padding: 5px 30px;
  font-size: 1em;
  font-weight: bold;
  line-height: 1;
  color: ${WHITE_COLOR};
  white-space: nowrap;
  vertical-align: baseline;
  border-radius: .25em;
`;

const ActivityDateElement = ({ date }) =>
  <StyledLi className="text-center">
    <StyledSpan className="label label-primary">
      <Moment format="DD.MM.YYYY">
        {date}
      </Moment>
    </StyledSpan>
  </StyledLi>;

ActivityDateElement.propTypes = {
  date: PropTypes.instanceOf(Date).isRequired
};

export default ActivityDateElement;
