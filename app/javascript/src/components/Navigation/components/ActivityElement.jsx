// @flow
import React from "react";
import type {Node} from 'react';
import styled from "styled-components";
import { FormattedDate } from "react-intl";

import {
  WHITE_COLOR,
  COLOR_CONCRETE,
  BORDER_GRAY_COLOR
} from "../../../config/constants/colors";

const StyledLi = styled.li`
  border-radius: 0.25em;
  margin-bottom: 1em;
  background-color: ${WHITE_COLOR};
  border: 1px solid ${COLOR_CONCRETE};
`;
const TimeSpan = styled.span`
  min-width: 150px;
  display: table-cell;
  vertical-align: middle;
  border-top-left-radius: 0.25em;
  border-bottom-left-radius: 0.25em;
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
`;

const ActivityElement = ({ activity }: Activity ): Node => (
  <StyledLi>
    <TimeSpan>
      <FormattedDate
        value={new Date(activity.createdAt)}
        hour="2-digit"
        minute="2-digit"
        timeZone={activity.timezone}
        hour12={false}
      />
    </TimeSpan>
    <TextSpan dangerouslySetInnerHTML={{ __html: activity.message }} />
  </StyledLi>
);

export default ActivityElement;
