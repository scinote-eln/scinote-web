import React, { Component } from "react";
import update from "immutability-helper";
import PropTypes from "prop-types";
import _ from "lodash";

class ValidatedForm extends Component {
  constructor(props) {
    super(props);

    this.state = {}

    this.setErrors = this.setErrors.bind(this);
    this.setErrorsForTag = this.setErrorsForTag.bind(this);
    this.errors = this.errors.bind(this);
    this.hasAnyError = this.hasAnyError.bind(this);
    this.hasErrorForTag = this.hasErrorForTag.bind(this);
    this.addErrorsForTag = this.addErrorsForTag.bind(this);
    this.clearErrorsForTag = this.clearErrorsForTag.bind(this);
    this.clearErrors = this.clearErrors.bind(this);
  }

  getChildContext() {
    // Pass functions downstream via context
    return {
      setErrors: this.setErrors,
      setErrorsForTag: this.setErrorsForTag,
      errors: this.errors,
      hasAnyError: this.hasAnyError,
      hasErrorForTag: this.hasErrorForTag,
      addErrorsForTag: this.addErrorsForTag,
      clearErrorsForTag: this.clearErrorsForTag,
      clearErrors: this.clearErrors
    };
  }

  setErrors(errors) {
    // This method is quite smart, in the sense that accepts either
    // errors in 3 shapes: localized error messages ({}),
    // unlocalized error messages ({}), or mere strings (unlocalized)
    const newState = {};
    _.entries(errors).forEach(([key, value]) => {
      const arr = _.isString(value) ? [value] : value;
      newState[key] = arr.map((el) => _.isString(el) ? { message: el } : el);
    });
    this.setState(newState);
  }

  setErrorsForTag(tag, errors) {
    const newState = update(this.state, { [tag]: { $set: errors } });
    this.setState(newState);
  }

  errors(tag) {
    return this.state[tag];
  }

  hasAnyError() {
    return _.values(this.state) &&
      _.flatten(_.values(this.state)).length > 0;
  }

  hasErrorForTag(tag) {
    return _.has(this.state, tag) && this.state[tag].length > 0;
  }

  addErrorsForTag(tag, errors) {
    let newState;
    if (_.has(this.state, tag)) {
      newState = update(this.state, { [tag]: { $push: errors } });
    } else {
      newState = update(this.state, { [tag]: { $set: errors } });
    }
    this.setState(newState);
  }

  clearErrorsForTag(tag) {
    const newState = update(this.state, { [tag]: { $set: [] } });
    this.setState(newState);
  }

  clearErrors() {
    this.setState({});
  }

  render() {
    return (
      <form {...this.props}>
        {this.props.children}
      </form>
    );
  }
}

ValidatedForm.propTypes = {
  children: PropTypes.node
}

ValidatedForm.defaultProps = {
  children: undefined
}

ValidatedForm.childContextTypes = {
  setErrors: PropTypes.func,
  setErrorsForTag: PropTypes.func,
  errors: PropTypes.func,
  hasAnyError: PropTypes.func,
  hasErrorForTag: PropTypes.func,
  addErrorsForTag: PropTypes.func,
  clearErrorsForTag: PropTypes.func,
  clearErrors: PropTypes.func
}

export default ValidatedForm;