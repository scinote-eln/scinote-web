import React from "react";
import PropTypes from "prop-types";
import {defineMessages, injectIntl, intlShape} from 'react-intl';
import { FormControl } from "react-bootstrap";

const messages = defineMessages({
    placeholder: { id: "settings_page.new_team.name_placeholder" }
});

const NameFormControl = ({intl}) =>
  <FormControl
    type="text"
    placeholder={intl.formatMessage(messages.placeholder)}
    autoFocus={true}
  />;

NameFormControl.PropTypes = {
    intl: intlShape.isRequired
};

export default injectIntl(NameFormControl);
