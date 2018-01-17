// @flow

import React from "react";
import moment from 'moment-timezone';
import { FormattedMessage } from "react-intl";
import styled from "styled-components";


import { isToday } from "../../../services/helpers/date_time_helper"
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

const ActivityDateElement = (props: { date: Date, timezone: string }) => {
  const massageDate = moment(props.date).tz(props.timezone).format("DD.MM.YYYY")
  const label = isToday(props.date) ? (
    <FormattedMessage id="activities.today"/>
  ) : (
    <span>{massageDate}</span>
  );
  return (
    <StyledLi className="text-center">
      <StyledSpan className="label label-primary">{label}</StyledSpan>
    </StyledLi>
  );
};

export default ActivityDateElement;
