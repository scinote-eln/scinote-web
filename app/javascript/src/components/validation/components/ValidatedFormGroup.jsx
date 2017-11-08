// @flow

import * as React from "react";
import { FormGroup } from "react-bootstrap";
import PropTypes from "prop-types";

type Props = {
  tag: string
};

const ValidatedFormGroup = (props: Props, context: any) => {
  // Remove additional props from the props
  const { tag, ...cleanProps } = props;

  const hasError = context.hasErrorForTag(tag);
  const formGroupClass = `form-group ${hasError ? " has-error" : ""}`;
  const validationState = hasError ? "error" : null;

  return (
    <FormGroup
      className={formGroupClass}
      validationState={validationState}
      {...cleanProps}
    />
  );
};

ValidatedFormGroup.contextTypes = {
  hasErrorForTag: PropTypes.func
}

export default ValidatedFormGroup;