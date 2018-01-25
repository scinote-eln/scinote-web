import React from "react";
import {defineMessages, injectIntl, intlShape} from 'react-intl';
import { ValidatedFormControl } from "../../../../../../components/validation";

const messages = defineMessages({
    placeholder: { id: "settings_page.new_team.name_placeholder" }
});

const NameFormControl = ({ intl, ...props }) =>
  <ValidatedFormControl
    type="text"
    placeholder={intl.formatMessage(messages.placeholder)}
    autoFocus={true}
    {...props}
  />;

NameFormControl.propTypes = {
  intl: intlShape.isRequired
};

export default injectIntl(NameFormControl);
