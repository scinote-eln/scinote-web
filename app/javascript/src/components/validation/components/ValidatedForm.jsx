// @flow

import * as React from "react";
import update from "immutability-helper";
import type {
  ValidationError,
  ValidationErrors
} from "flow-typed";
import PropTypes from "prop-types";
import _ from "lodash";

type Props = {
  children?: React.Node
};

type State = {
  [string]: Array<ValidationError>
};

type ChildContext = {
  setErrors: Function,
  setErrorsForTag: Function,
  errors: Function,
  hasAnyError: Function,
  hasErrorForTag: Function,
  addErrorsForTag: Function,
  clearErrorsForTag: Function,
  clearErrors: Function
};

class ValidatedForm extends React.Component<Props, State> {
  static defaultProps = {
    children: undefined
  }

  static parseErrors(errors: ValidationErrors): Array<ValidationError> {
    // This method is quite smart, in the sense that accepts either
    // errors in 3 shapes: localized error messages ({}),
    // unlocalized error messages ({}), or mere strings (unlocalized)
    const arr = _.isString(errors) ? [errors] : errors;
    return arr.map(
      (el: string | ValidationError) => _.isString(el) ? { message: el } : el
    );
  }

  constructor(props: Props) {
    super(props);

    this.state = {};

    (this: any).setErrors = this.setErrors.bind(this);
    (this: any).setErrorsForTag = this.setErrorsForTag.bind(this);
    (this: any).errors = this.errors.bind(this);
    (this: any).hasAnyError = this.hasAnyError.bind(this);
    (this: any).hasErrorForTag = this.hasErrorForTag.bind(this);
    (this: any).addErrorsForTag = this.addErrorsForTag.bind(this);
    (this: any).clearErrorsForTag = this.clearErrorsForTag.bind(this);
    (this: any).clearErrors = this.clearErrors.bind(this);
  }

  getChildContext(): ChildContext {
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

  setErrors(errors: { [string]: ValidationErrors }): void {
    const newState = {};
    _.entries(errors).forEach(([key, value]) => {
      newState[key] = ValidatedForm.parseErrors(value);
    });
    this.setState(newState);
  }

  setErrorsForTag(tag: string, errors: ValidationErrors): void {
    const newState = update(this.state, {
      [tag]: { $set: ValidatedForm.parseErrors(errors) }
    });
    this.setState(newState);
  }

  errors(tag: string): Array<ValidationError> {
    return this.state[tag];
  }

  hasAnyError(): boolean {
    return _.values(this.state) &&
      _.flatten(_.values(this.state)).length > 0;
  }

  hasErrorForTag(tag: string): boolean {
    return _.has(this.state, tag) && this.state[tag].length > 0;
  }

  addErrorsForTag(tag: string, errors: ValidationErrors): void {
    let newState: State;
    if (_.has(this.state, tag)) {
      newState = update(this.state, { [tag]: { $push: errors } });
    } else {
      newState = update(this.state, { [tag]: { $set: errors } });
    }
    this.setState(newState);
  }

  clearErrorsForTag(tag: string): void {
    const newState = update(this.state, { [tag]: { $set: [] } });
    this.setState(newState);
  }

  clearErrors(): void {
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
