// @flow

import * as React from "react";
import { Button } from "react-bootstrap";
import PropTypes from "prop-types";

type Props = {
  children?: React.Node
};

const ValidatedSubmitButton = (props: Props, context: any) =>
  <Button {...props} disabled={context.hasAnyError()}>
    {props.children}
  </Button>
;

ValidatedSubmitButton.defaultProps = {
  children: undefined
}

ValidatedSubmitButton.contextTypes = {
  hasAnyError: PropTypes.func
}

export default ValidatedSubmitButton;