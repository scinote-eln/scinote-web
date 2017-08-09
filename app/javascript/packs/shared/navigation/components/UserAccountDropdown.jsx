import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { NavDropdown, MenuItem, Image } from "react-bootstrap";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";

import { getCurrentUser } from "../../actions/UsersActions";

const StyledNavDropdown = styled(NavDropdown)`
& #user-account-dropdown {
  padding-top: 10px;
  padding-bottom: 10px;
}
`;

class UserAccountDropdown extends Component {
  componentDidMount() {
    this.props.getCurrentUser();
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
        <MenuItem href="/users/sign_out">
          <FormattedMessage id="user_account_dropdown.log_out" />
        </MenuItem>
      </StyledNavDropdown>
    );
  }
}

UserAccountDropdown.propTypes = {
  getCurrentUser: PropTypes.func.isRequired,
  current_user: PropTypes.shape({
    id: PropTypes.number.isRequired,
    fullName: PropTypes.string.isRequired,
    avatarPath: PropTypes.string.isRequired
  }).isRequired
};

// Map the states from store to component
const mapStateToProps = ({ current_user }) => ({ current_user });

// Map the fetch activity action to component
const mapDispatchToProps = dispatch => ({
  getCurrentUser() {
    dispatch(getCurrentUser());
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(
  UserAccountDropdown
);
