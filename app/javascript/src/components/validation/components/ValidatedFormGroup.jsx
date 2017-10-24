import React, { Component } from "react";
import { FormGroup } from "react-bootstrap";
import PropTypes from "prop-types";

class ValidatedFormGroup extends Component {
  render() {
    // Remove additional props from the props
    const { tag, ...cleanProps } = this.props;

    const hasError = this.context.hasErrorForTag(tag);
    const formGroupClass = `form-group ${hasError ? " has-error" : ""}`;
    const validationState = hasError ? "error" : null;

    return (
      <FormGroup
        className={formGroupClass}
        validationState={validationState}
        {...cleanProps}
      />
    );
  }
}

ValidatedFormGroup.propTypes = {
  tag: PropTypes.string.isRequired
}

ValidatedFormGroup.contextTypes = {
  hasErrorForTag: PropTypes.func
}

export default ValidatedFormGroup;