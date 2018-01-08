// @flow

import React from "react";
import type { Node } from "react";
import { FormattedDate, FormattedMessage } from "react-intl";
import { Tooltip, OverlayTrigger } from "react-bootstrap";
import styled from "styled-components";

import {
  WHITE_COLOR,
  COLOR_CONCRETE,
  BORDER_GRAY_COLOR
} from "../../../config/constants/colors";

import { NAME_TRUNCATION_LENGTH } from "../../../config/constants/numeric";

type InputActivity = {
  activity: Activity
}

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

function truncatedTooltip(id: string, text: any): Node {
  return (
    <OverlayTrigger
      overlay={<Tooltip id={id}>{text}</Tooltip>}
      placement="bottom"
    >
      <span>{text.substring(0, NAME_TRUNCATION_LENGTH)}...</span>
    </OverlayTrigger>
  );
}

function taskPath(activity: Activity): Node {
  return (
    <span>
      &nbsp; [&nbsp;<FormattedMessage id="general.project" />:&nbsp;
      {activity.project.length > NAME_TRUNCATION_LENGTH ? (
        truncatedTooltip(
          "activity_modal.long_project_tooltip",
          activity.project
        )
      ) : (
        <span>{activity.project}</span>
      )},&nbsp;
      <FormattedMessage id="general.task" />:&nbsp;
      {activity.task.length > NAME_TRUNCATION_LENGTH ? (
        truncatedTooltip("activity_modal.long_task_tooltip", activity.task)
      ) : (
        <span>{activity.task}</span>
      )}&nbsp;]
    </span>
  );
}

const ActivityElement = ({ activity }: InputActivity ): Node => (
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
    <TextSpan>
      <span dangerouslySetInnerHTML={{ __html: activity.message }} />
      {activity.task && taskPath(activity)}
    </TextSpan>
  </StyledLi>
);

export default ActivityElement;
