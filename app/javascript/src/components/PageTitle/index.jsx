// @flow
import React from "react";
import type { Node } from "react";
import type { MessageDescriptor } from "flow-typed";
import DocumentTitle from "react-document-title";
import { formatMessage, defineMessages, injectIntl } from "react-intl";

type Props = {
  intl: any,
  localeID: string,
  values?: any,
  children: Node
};

const PageTitle = (props: Props): Node => {
  const message = defineMessages({
    placeholder: { id: props.localeID, values: props.values }
  });
  const title = props.intl.formatMessage(message.placeholder);
  return <DocumentTitle title={title}>{props.children}</DocumentTitle>;
};

PageTitle.defaultProps = {
  values: null
};

export default injectIntl(PageTitle);
