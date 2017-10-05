import React, { Component } from "react";
import { connect } from "react-redux";
import { func, shape, string, number } from "prop-types";
import { NavDropdown, MenuItem, Image } from "react-bootstrap";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";
import { SIGN_IN_PATH } from "../../../config/routes";

import { getCurrentUser, destroyState } from "../../actions/UsersActions";
import { signOutUser } from "../../../services/api/users_api";

const StyledNavDropdown = styled(NavDropdown)`
  & #user-account-dropdown {
    padding-top: 10px;
    padding-bottom: 10px;
  }
`;

class UserAccountDropdown extends Component {
  componentDidMount() {
    this.props.getCurrentUser();
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
    return (
      <StyledNavDropdown
        id="user-account-dropdown"
        className="dropdown"
        noCaret
        title={
          <span>
            <FormattedMessage
              id="user_account_dropdown.greeting"
              values={{ name: this.props.current_user.fullName }}
            />&nbsp;
            <Image
              src={this.props.current_user.avatarPath}
              alt={this.props.current_user.fullName}
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
  getCurrentUser: func.isRequired,
  destroyState: func.isRequired,
  current_user: shape({
    id: number.isRequired,
    fullName: string.isRequired,
    avatarPath: string.isRequired
  }).isRequired
};

// Map the states from store to component
const mapStateToProps = ({ current_user }) => ({ current_user });

export default connect(mapStateToProps, { destroyState, getCurrentUser })(
  UserAccountDropdown
);
