import React from "react";
import PropTypes from "prop-types";
import { Col, Row } from "react-bootstrap";
import { FormattedTime } from "react-intl";

import CustomNavItem from "./CustomNavItem";

const NotificationItem = ({ notification }) => {
  const { title, message, created_at, type_of } = notification;

  return (
    <CustomNavItem>
      <Row>
        <Col xs={2}>
          <div className="text-center">
            <span className="assignment">
              <i className="fa fa-newspaper-o" />
            </span>
          </div>
        </Col>

        <Col xs={10}>
          <span dangerouslySetInnerHTML={{ __html: title }} />
          <br />
          <FormattedTime
            value={created_at}
            day="numeric"
            month="numeric"
            year="numeric"
            hour="numeric"
            minute="numeric"
          />
          | <span dangerouslySetInnerHTML={{ __html: message }} />
        </Col>
      </Row>
    </CustomNavItem>
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
