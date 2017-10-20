import React, { Component } from "react";
import { FormControl } from "react-bootstrap";
import PropTypes from "prop-types";

class ValidatedFormControl extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.cleanProps = this.cleanProps.bind(this);
  }

  handleChange(e) {
    const tag = this.props.tag;
    const messageIds = this.props.messageIds;
    const value = e.target.value;

    // Pass-through "original" onChange
    if (_.has(this.props, "onChange")) {
      this.props.onChange(e);
    }

    // Validate the field
    let errors = [];
    this.props.validatorsOnChange.forEach((validator) => {
      errors = errors.concat(validator(value, messageIds));
    });
    this.context.setErrorsForTag(tag, errors);
  }

  cleanProps() {
    // Remove additional props from the props
    const {
      tag,
      messageIds,
      validatorsOnChange,
      onChange,
      ...cleanProps
    } = this.props;
    return cleanProps;
  }

  render() {
    return (
      <FormControl
        onChange={this.handleChange}
        {...this.cleanProps()}
      />
    );
  }
}

ValidatedFormControl.propTypes = {
  tag: PropTypes.string.isRequired,
  messageIds: PropTypes.objectOf(PropTypes.string),
  validatorsOnChange: PropTypes.arrayOf(PropTypes.func),
  onChange: PropTypes.func
}

ValidatedFormControl.defaultProps = {
  messageIds: {},
  validatorsOnChange: [],
  onChange: undefined
}

ValidatedFormControl.contextTypes = {
  setErrorsForTag: PropTypes.func
}

export default ValidatedFormControl;