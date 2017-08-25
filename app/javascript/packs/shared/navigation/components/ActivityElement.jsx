import React from "react";
import PropTypes from "prop-types";
import Moment from "react-moment";
import styled from "styled-components";

import {
  WHITE_COLOR,
  COLOR_CONCRETE,
  BORDER_GRAY_COLOR
} from "../../../app/constants/colors";

const StyledLi = styled.li`
  border-radius: .25em;
  margin-bottom: 1em;
  background-color: ${WHITE_COLOR};
  border: 1px solid ${COLOR_CONCRETE};
`;
const TimeSpan = styled.span`
  min-width: 150px;
  display: table-cell;
  vertical-align: middle;
  border-top-left-radius: .25em;
  border-bottom-left-radius: .25em;
  border: 3px solid ${BORDER_GRAY_COLOR};
  background-color: ${BORDER_GRAY_COLOR};
  padding-left: 10px;
  padding-right: 10px;
  vertical-align: top;
`;

const TextSpan = styled.span`
  display: table-cell;
  padding: 3px 10px;
  text-align: justify;
`

const ActivityElement = ({ activity }) =>
  <StyledLi>
    <TimeSpan>
      <Moment format="HH.mm">
        {activity.created_at}
      </Moment>
    </TimeSpan>
    <TextSpan dangerouslySetInnerHTML={{ __html: activity.message }} />
  </StyledLi>;

ActivityElement.propTypes = {
  activity: PropTypes.shape({
    message: PropTypes.string.isRequired,
    created_at: PropTypes.string.isRequired
  }).isRequired
};

export default ActivityElement;
