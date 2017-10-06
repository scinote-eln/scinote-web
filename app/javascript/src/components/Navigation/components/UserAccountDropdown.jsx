import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { NavDropdown, MenuItem, Image } from "react-bootstrap";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import { getCurrentUser } from "../../../services/api/users_api";
import { addCurrentUser } from "../../actions/UsersActions";

const StyledNavDropdown = styled(NavDropdown)`
  & #user-account-dropdown {
    padding-top: 10px;
    padding-bottom: 10px;
  }
`;

const StyledAvatar = styled(Image)`
  max-width: 30px;
  max-height: 30px;
`;

class UserAccountDropdown extends Component {
  componentDidMount() {
    getCurrentUser().then(data => {
      this.props.addCurrentUser(data);
    });
  }

  render() {
    const { fullName, avatarThumb } = this.props.current_user;
    return (
      <StyledNavDropdown
        id="user-account-dropdown"
        className="dropdown"
        noCaret
        title={
          <span>
            <FormattedMessage
              id="user_account_dropdown.greeting"
              values={{ name: fullName }}
            />&nbsp;
            <StyledAvatar
              src={`${avatarThumb }?${new Date().getTime()}`}
              alt={fullName}
              circle
            />
          </span>
        }
      >
        <MenuItem href="/settings">
          <FormattedMessage id="user_account_dropdown.settings" />
        </MenuItem>
        <MenuItem divider />
        <MenuItem href="/users/sign_out">
          <FormattedMessage id="user_account_dropdown.log_out" />
        </MenuItem>
      </StyledNavDropdown>
    );
  }
}

UserAccountDropdown.propTypes = {
  addCurrentUser: PropTypes.func.isRequired,
  current_user: PropTypes.shape({
    id: PropTypes.number.isRequired,
    fullName: PropTypes.string.isRequired,
    avatarThumb: PropTypes.string.isRequired
  }).isRequired
};

// Map the states from store to component
const mapStateToProps = ({ current_user }) => ({ current_user });

export default connect(mapStateToProps, { addCurrentUser })(
  UserAccountDropdown
);
