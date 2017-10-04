// @flow

import React from "react";
import Moment from "react-moment";
import { FormattedMessage } from "react-intl";
import styled from "styled-components";

import { WHITE_COLOR } from "../../../config/constants/colors";

const StyledLi = styled.li`margin-bottom: 1em;`;

const StyledSpan = styled.span`
  display: inline;
  padding: 5px 30px;
  font-size: 1em;
  font-weight: bold;
  line-height: 1;
  color: ${WHITE_COLOR};
  white-space: nowrap;
  vertical-align: baseline;
  border-radius: 0.25em;
`;

const ActivityDateElement = (props: { date: Date, today?: boolean }) => {
  const label = props.today ? (
    <FormattedMessage id="activities.today"/>
  ) : (
    <Moment format="DD.MM.YYYY">{props.date}</Moment>
  );
  return (
    <StyledLi className="text-center">
      <StyledSpan className="label label-primary">{label}</StyledSpan>
    </StyledLi>
  );
};

export default ActivityDateElement;
