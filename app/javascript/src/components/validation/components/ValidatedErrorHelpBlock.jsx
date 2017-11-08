// @flow

import * as React from "react";
import { HelpBlock } from "react-bootstrap";
import { FormattedMessage } from "react-intl";
import type { ValidationError } from "flow-typed";
import PropTypes from "prop-types";
import styled from "styled-components";
import shortid from "shortid";

const MyHelpBlock = styled(HelpBlock)`
  & > span {
    margin-right: 5px;
  }
`;

type Props = {
  tag: string
};

class ValidatedErrorHelpBlock extends React.Component<Props> {
  static renderErrorMessage(error: ValidationError): React.Node {
    const key = shortid.generate();
    if (error.intl) {
      return (
        <FormattedMessage
          key={key}
          id={error.messageId}
          values={error.values}
        />
      );
    }
    return <span key={key}>{error.message}</span>;
  }

  cleanProps() {
    // Remove additional props from the props
    const { tag, ...cleanProps } = this.props;
    return cleanProps;
  }

  render() {
    // Remove additional props from the props
    const { tag, ...cleanProps } = this.props;

    const errors = this.context.errors(tag) || [];
    return (
      <MyHelpBlock {...cleanProps}>
        {errors.map(
          (error: ValidationError) => ValidatedErrorHelpBlock.renderErrorMessage(error)
        )}
      </MyHelpBlock>
    );
  }
}

ValidatedErrorHelpBlock.contextTypes = {
  errors: PropTypes.func
}

export default ValidatedErrorHelpBlock;