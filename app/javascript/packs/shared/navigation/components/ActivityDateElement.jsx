import React from "react";
import PropTypes from "prop-types";
import { FormattedDate } from "react-intl";

const ActivityDateElement = ({ date }) =>
  <li className="data-element">
    <FormattedDate value={date} day="2-digit" month="2-digit" year="numeric" />
  </li>;

ActivityDateElement.propTypes = {
  date: PropTypes.instanceOf(Date).isRequired
};

export default ActivityDateElement;
