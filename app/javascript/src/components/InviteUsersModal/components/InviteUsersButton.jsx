// @flow
import React from "react";
import { FormattedMessage } from "react-intl";
import { DropdownButton, MenuItem } from "react-bootstrap";

type Props = {
  handleClick: Function,
  status: boolean
};

const InviteUsersButton = ({ handleClick, status }: Props) => {
  return (
    <DropdownButton
      bsStyle="primary"
      title={<FormattedMessage id="invite_users.dropdown_button.invite" />}
      id="invite_users.submit_button"
      disabled={status}
    >
      <MenuItem onClick={() => handleClick("guest")}>
        <FormattedMessage id="invite_users.dropdown_button.guest" />
      </MenuItem>
      <MenuItem onClick={() => handleClick("normal_user")}>
        <FormattedMessage id="invite_users.dropdown_button.normal_user" />
      </MenuItem>
      <MenuItem onClick={() => handleClick("admin")}>
        <FormattedMessage id="invite_users.dropdown_button.admin" />
      </MenuItem>
    </DropdownButton>
  );
};

export default InviteUsersButton;
