import React from "react";
import { Image } from "react-bootstrap";
import PropTypes from "prop-types";

const NotificationImage = ({className, type, avatar}) => {
  const delegator = {
      recent_changes: (
          <Image
              className="avatar"
              src={`${avatar }?${new Date().getTime()}`}
              circle
          />
      ),
      system_message: (
          <span className="system-message">
              <i className="glyphicon glyphicon-tower" />
          </span>
      ),
      deliver: (
          <span className="deliver">
              <i className="fa fa-truck" />
          </span>
      ),
      assignment: (
          <span className="assignment">
              <i className="fa fa-newspaper-o" />
          </span>
      )
  }
  return (
    <div className={`text-center ${className}`} >
      {delegator[type]}
    </div>
  );
};

NotificationImage.defaultProps = {
  avatar: ''
};

NotificationImage.propTypes = {
  className: PropTypes.string.isRequired,
  type: PropTypes.string.isRequired,
  avatar: PropTypes.string
};

export default NotificationImage;
