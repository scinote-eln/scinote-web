// @flow

import React from "react";
import { Button } from "react-bootstrap";
import PropTypes from "prop-types";
import type { Node } from 'react';

type Props = {
  children?: Node
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