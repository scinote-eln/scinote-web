import React from "react";
import PropTypes from "prop-types";
import { FormattedTime } from "react-intl";

const ActivityElement = ({ activity }) => {
  return (
    <li>
      <span>
        <FormattedTime
          value={activity.created_at}
          hour="numeric"
          minute="numeric"
        />
      </span>
      <span dangerouslySetInnerHTML={{ __html: activity.message }} />
    </li>
  );
};

ActivityElement.propTypes = {
  activity: PropTypes.shape({
    message: PropTypes.string.isRequired,
    created_at: PropTypes.string.isRequired
  })
};

export default ActivityElement;
