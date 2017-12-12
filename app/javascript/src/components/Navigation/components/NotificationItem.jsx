import React from "react";
import PropTypes from "prop-types";
import { Col, Row } from "react-bootstrap";
import { FormattedTime } from "react-intl";
import styled from "styled-components";

import CustomNavItem from "./CustomNavItem";
import NotificationImage from "./NotificationImage";
import {
  MAIN_COLOR_BLUE,
  COLOR_ORANGE,
  ICON_GREEN_COLOR,
  WILD_SAND_COLOR
} from "../../../config/constants/colors";

const StyledListItem = styled(CustomNavItem)`
  border-bottom: 1px solid #d2d2d2;
  padding-bottom: 10px;
  padding-top: 10px;
`;

const StyledNotificationImage = styled(NotificationImage)`
  margin-left: 12px;

  .avatar {
    top: 0px;
    margin-top: 5px;
    height: 45px;
    width: 45px;
  }

  .assignment {
    background-color: ${MAIN_COLOR_BLUE};
    border-radius: 50%;
    color: ${WILD_SAND_COLOR};
    display: block;
    font-size: 23px;
    height: 45px;
    padding-top: 5px;
    width: 45px;
  }

  .deliver {
    background-color: ${COLOR_ORANGE};
    border-radius: 50%;
    color: ${WILD_SAND_COLOR};
    display: block;
    font-size: 23px;
    height: 45px;
    padding-top: 5px;
    width: 45px;
  }

  .system-message {
    background-color: ${ICON_GREEN_COLOR};
    border-radius: 50%;
    color: ${WILD_SAND_COLOR};
    display: block;
    font-size: 23px;
    height: 45px;
    padding-top: 8px;
    width: 45px;
  }
`;

const NotificationItem = ({ notification }) => {
  const { title, message, created_at, type_of, avatarThumb } = notification;

  return (
    <StyledListItem>
      <Row>
        <Col xs={2}>
          <StyledNotificationImage type={type_of} avatar={avatarThumb} />
        </Col>

        <Col xs={10}>
          <strong dangerouslySetInnerHTML={{ __html: title }} />
          <br />
          <FormattedTime
            value={created_at}
            day="numeric"
            month="numeric"
            year="numeric"
            hour="numeric"
            minute="numeric"
          />&nbsp;|&nbsp;<span dangerouslySetInnerHTML={{ __html: message }} />
        </Col>
      </Row>
    </StyledListItem>
  );
};

NotificationItem.propTypes = {
  notification: PropTypes.shape({
    id: PropTypes.number.isRequired,
    title: PropTypes.string.isRequired,
    message: PropTypes.string.isRequired,
    type_of: PropTypes.string.isRequired,
    created_at: PropTypes.string.isRequired
  }).isRequired
};

export default NotificationItem;
