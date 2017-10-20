import React, { Component } from "react";
import { FormGroup } from "react-bootstrap";
import PropTypes from "prop-types";

class ValidatedFormGroup extends Component {
  constructor(props) {
    super(props);

    this.cleanProps = this.cleanProps.bind(this);
  }

  cleanProps() {
    // Remove additional props from the props
    const { tag, ...cleanProps } = this.props;
    return cleanProps;
  }

  render() {
    const hasError = this.context.hasErrorForTag(this.props.tag);
    const formGroupClass = `form-group ${hasError ? " has-error" : ""}`;
    const validationState = hasError ? "error" : null;

    return (
      <FormGroup
        className={formGroupClass}
        validationState={validationState}
        {...this.cleanProps()}
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