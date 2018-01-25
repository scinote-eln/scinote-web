// @flow

import React from "react";
import { Image } from "react-bootstrap";

type Props = {
  className: string,
  type: string,
  avatar: string
};

const NotificationImage = ({className, type, avatar}: Props) => {
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

export default NotificationImage;
