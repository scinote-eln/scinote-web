import React from 'react';
import PropTypes from 'prop-types';
import { FormattedMessage } from 'react-intl';
import { DropdownButton, MenuItem } from 'react-bootstrap';

const InviteUsersButton = props =>
	<DropdownButton
		bsStyle={'primary'}
		title={<FormattedMessage id="invite_users.dropdown_button.invite" />}
		id="invite_users.submit_button"
	>
		<MenuItem onClick={() => props.handleClick('guest')}>
			<FormattedMessage id="invite_users.dropdown_button.guest" />
		</MenuItem>
		<MenuItem onClick={() => props.handleClick('normal_user')}>
			<FormattedMessage id="invite_users.dropdown_button.normal_user" />
		</MenuItem>
		<MenuItem onClick={() => props.handleClick('admin')}>
			<FormattedMessage id="invite_users.dropdown_button.admin" />
		</MenuItem>
	</DropdownButton>;

InviteUsersButton.propTypes = {
	handleClick: PropTypes.func.isRequired
};

export default InviteUsersButton;
