import React from 'react';
import PropTypes from 'prop-types';
import { FormattedMessage } from 'react-intl';
import { FormGroup, HelpBlock } from 'react-bootstrap';
import TagsInput from 'react-tagsinput';

import { INVITE_USERS_LIMIT } from '../../../config/constants/numeric';

const InviteUsersForm = props =>
	<FormGroup controlId="form-invite-user">
		<p>
			<FormattedMessage id="invite_users.input_text" values={{team: props.teamName}} />
		</p>
		<TagsInput
			value={props.tags}
			addKeys={[9, 13, 188]}
			addOnPaste
			onlyUnique
			maxTags={INVITE_USERS_LIMIT}
			inputProps={{
				placeholder: ''
			}}
			onChange={props.handleChange}
		/>
		<HelpBlock>
			<em>
				<FormattedMessage id="invite_users.input_help" />
			</em>
		</HelpBlock>
	</FormGroup>;

InviteUsersForm.propTypes = {
	tags: PropTypes.arrayOf(PropTypes.string.isRequired).isRequired,
	handleChange: PropTypes.func.isRequired,
	teamName: PropTypes.string.isRequired
};

export default InviteUsersForm;
