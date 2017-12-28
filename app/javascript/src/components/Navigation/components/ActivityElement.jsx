// @flow

import React from "react";
import Moment from "react-moment";
import { Tooltip, OverlayTrigger } from "react-bootstrap";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import {
  WHITE_COLOR,
  COLOR_CONCRETE,
  BORDER_GRAY_COLOR
} from "../../../config/constants/colors";

import { NAME_TRUNCATION_LENGTH } from "../../../config/constants/numeric";

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
    <TextSpan>
      <span dangerouslySetInnerHTML={{ __html: activity.message }} />
      {activity.task &&
        <span>&nbsp;
          [&nbsp;<FormattedMessage id="general.project" />:&nbsp;
          {activity.project.length > NAME_TRUNCATION_LENGTH ? (
            <OverlayTrigger overlay={(
              <Tooltip id="activity_modal.long_project_tooltip">
                {activity.project}
              </Tooltip>
            )} placement="bottom">
                <span>
                  {activity.project.substring(0, NAME_TRUNCATION_LENGTH)}...
                </span>
            </OverlayTrigger>
          ):(
            <span>{activity.project}</span>
          )},&nbsp;
          <FormattedMessage id="general.task" />:&nbsp;
          {activity.task.length > NAME_TRUNCATION_LENGTH ? (
            <OverlayTrigger overlay={(
              <Tooltip id="activity_modal.long_task_tooltip">
                {activity.task}
              </Tooltip>
            )} placement="bottom">
                <span>
                  {activity.task.substring(0, NAME_TRUNCATION_LENGTH)}...
                </span>
            </OverlayTrigger>
          ):(
            <span>{activity.task}</span>
          )}&nbsp;]
        </span>
      }
    </TextSpan>
  </StyledLi>;

export default ActivityElement;
