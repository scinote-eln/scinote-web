// @flow

import * as React from "react";
import { FormControl } from "react-bootstrap";
import type { ValidationError } from "flow-typed";
import PropTypes from "prop-types";
import _ from "lodash";

type Props = {
  tag: string,
  messageIds: {[string]: Array<string>},
  onChange?: Function,
  validatorsOnChange: Array<Function>,
  children?: React.Node
};

class ValidatedFormControl extends React.Component<Props> {
  static defaultProps = {
    onChange: undefined,
    children: undefined
  }

  constructor(props: Props) {
    super(props);

    (this: any).handleChange = this.handleChange.bind(this);
    (this: any).cleanProps = this.cleanProps.bind(this);
  }

  handleChange(e: SyntheticEvent<HTMLInputElement>): void {
    const tag = this.props.tag;
    const messageIds = this.props.messageIds;
    const target = e.target;

    // Pass-through "original" onChange
    if (_.has(this.props, "onChange") && this.props.onChange !== undefined) {
      this.props.onChange(e);
    }

    // Validate the field
    let errors: Array<ValidationError> = [];
    this.props.validatorsOnChange.forEach((validator: Function) => {
      errors = errors.concat(validator(target, messageIds));
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

ValidatedFormControl.contextTypes = {
  setErrorsForTag: PropTypes.func
}

export default ValidatedFormControl;