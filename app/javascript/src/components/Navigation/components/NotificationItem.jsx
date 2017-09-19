import React from "react";
import PropTypes from "prop-types";
import { Col, Row } from "react-bootstrap";
import { FormattedTime } from "react-intl";
import styled from "styled-components";

import CustomNavItem from "./CustomNavItem";
import NotificationImage from "./NotificationImage";

const StyledListItem = styled(CustomNavItem)`
  border-bottom: 1px solid #d2d2d2;
  padding-bottom: 10px;
  padding-top: 10px;
`;

const NotificationItem = ({ notification }) => {
  const { title, message, created_at, type_of } = notification;

  return (
    <StyledListItem>
      <Row>
        <Col xs={2}>
          <NotificationImage type={type_of} />
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
