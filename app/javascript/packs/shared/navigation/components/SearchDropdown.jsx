import React, { Component } from "react";
import { NavDropdown, MenuItem } from "react-bootstrap";

import { SEARCH_PATH } from "../../../app/routes";

class SearchDropdown extends Component {
  constructor(props) {
    super(props);
    this.state = { searchTerm: "" };
    this.handleSearchTermChange = this.handleSearchTermChange.bind(this);
    this.handleKeyPress = this.handleKeyPress.bind(this);
    this.setFocusToInput = this.setFocusToInput.bind(this);
  }

  setFocusToInput(ev) {
    this.navSearchInput.focus();
    ev.stopPropagation();
    ev.nativeEvent.stopImmediatePropagation();
  }

  handleKeyPress(ev) {
    if (ev.charCode === 13) {
      window.location = `${SEARCH_PATH}?q=${this.state.searchTerm}`;
      this.setState({ searchTerm: "" });
    }
  }

  handleSearchTermChange(ev) {
    this.setState({ searchTerm: ev.target.value });
  }

  render() {
    return (
      <NavDropdown
        noCaret
        title={<span className="glyphicon glyphicon-search" />}
        onClick={this.setFocusToInput}
        id="search-dropdown"
      >
        <MenuItem>
          <input
            onChange={this.handleSearchTermChange}
            onClick={this.setFocusToInput}
            onKeyPress={this.handleKeyPress}
            ref={el => {
              this.navSearchInput = el;
            }}
            type="text"
            placeholder="Search"
          />
        </MenuItem>
      </NavDropdown>
    );
  }
}

export default SearchDropdown;
