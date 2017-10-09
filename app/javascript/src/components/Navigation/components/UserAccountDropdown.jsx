import React, { Component } from "react";
import { connect } from "react-redux";
import { func, shape, string, number } from "prop-types";
import { NavDropdown, MenuItem, Image } from "react-bootstrap";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";
import { SIGN_IN_PATH } from "../../../config/routes";

import { addCurrentUser, destroyState } from "../../actions/UsersActions";
import { signOutUser, getCurrentUser } from "../../../services/api/users_api";

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
    this.signOut = this.signOut.bind(this);
  }

  signOut() {
    document.querySelector('meta[name="csrf-token"]').remove();
    signOutUser().then(() => {
      this.props.destroyState();
      window.location = SIGN_IN_PATH;
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
        <MenuItem onClick={this.signOut}>
          <FormattedMessage id="user_account_dropdown.log_out" />
        </MenuItem>
      </StyledNavDropdown>
    );
  }
}

UserAccountDropdown.propTypes = {
  addCurrentUser: func.isRequired,
  destroyState: func.isRequired,
  current_user: shape({
    id: number.isRequired,
    fullName: string.isRequired,
    avatarThumb: string.isRequired
  }).isRequired
};

// Map the states from store to component
const mapStateToProps = ({ current_user }) => ({ current_user });

export default connect(mapStateToProps, { destroyState, addCurrentUser })(
  UserAccountDropdown
);
