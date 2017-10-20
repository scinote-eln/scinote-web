import React from "react";
import { Button } from "react-bootstrap";
import PropTypes from "prop-types";

const ValidatedSubmitButton = (props, context) =>
  <Button {...props} disabled={context.hasAnyError()}>
    {props.children}
  </Button>
;

ValidatedSubmitButton.propTypes = {
  children: PropTypes.node
}

ValidatedSubmitButton.defaultProps = {
  children: undefined
}

ValidatedSubmitButton.contextTypes = {
  hasAnyError: PropTypes.func
}

export default ValidatedSubmitButton;