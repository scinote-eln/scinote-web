import React, { Component } from "react";
import { NavDropdown, MenuItem } from "react-bootstrap";

class SearchDropdown extends Component {
  constructor(props) {
    super(props);
    this.state = { searchTerm: "" };
    this.handleSearchTermChange = this.handleSearchTermChange.bind(this);
  }

  handleSearchTermChange(ev) {
    ev.preventDefault();
    this.setState({ searchTerm: ev.target.value });
  }

  handleRootClose(ev) {
  }

  render() {
    return (
      <NavDropdown
        noCaret
        title={<span className="glyphicon glyphicon-search" />}
        id="team-switch"
      >
        <MenuItem
          onSelect={this.triggerSearch}
          eventKey="search"
          key="navSearchInput"
        >
        </MenuItem>
      </NavDropdown>
    );
  }
}

export default SearchDropdown;
