import React, { Component } from "react";
import {
  NavDropdown,
  MenuItem,
  FormGroup,
  InputGroup,
  Glyphicon
} from "react-bootstrap";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";
import { SEARCH_PATH } from "../../../config/routes";
import { ENTER_KEY_CODE } from "../../../config/constants/numeric";

const StyledFormGroup = styled(FormGroup)`
  margin-bottom: 0px;
`;

const StyledMenuItem = styled(MenuItem)`
  padding-top: 10px;
  padding-bottom: 10px;
`;

const StyledNavDropdown = styled(NavDropdown)`
  & > .dropdown-menu {
    width: 250px;
  }
`;

class SearchDropdown extends Component {
  constructor(props) {
    super(props);
    this.state = { searchTerm: "" };
    this.handleSearchTermChange = this.handleSearchTermChange.bind(this);
    this.handleKeyPress = this.handleKeyPress.bind(this);
    this.setFocusToInput = this.setFocusToInput.bind(this);
    this.submitSearch = this.submitSearch.bind(this);
  }

  setFocusToInput(ev) {
    this.navSearchInput.focus();
    ev.stopPropagation();
    ev.nativeEvent.stopImmediatePropagation();
  }

  handleKeyPress(ev) {
    if (ev.charCode === ENTER_KEY_CODE) {
      this.submitSearch();
    }
  }

  handleSearchTermChange(ev) {
    this.setState({ searchTerm: ev.target.value });
  }

  submitSearch() {
    window.location = `${SEARCH_PATH}?q=${this.state.searchTerm}`;
    this.setState({ searchTerm: "" });
  }

  render() {
    return (
      <StyledNavDropdown
        noCaret
        title={
          <span>
            <span className="fas fa-search" />&nbsp;
            <span className="visible-xs-inline visible-sm-inline">
              <FormattedMessage id="navbar.search_label" />
            </span>
          </span>
        }
        onClick={this.setFocusToInput}
        id="search-dropdown"
      >
        <StyledMenuItem>
          <StyledFormGroup>
            <InputGroup>
              <input
                onChange={this.handleSearchTermChange}
                onClick={this.setFocusToInput}
                onKeyPress={this.handleKeyPress}
                ref={el => {
                  this.navSearchInput = el;
                }}
                type="text"
                placeholder="Search"
                className="form-control"
              />
              <InputGroup.Addon
                onClick={this.submitSearch}
                className="visible-xs visible-sm"
              >
                <Glyphicon glyph="menu-right" />
              </InputGroup.Addon>
            </InputGroup>
          </StyledFormGroup>
        </StyledMenuItem>
      </StyledNavDropdown>
    );
  }
}

export default SearchDropdown;
