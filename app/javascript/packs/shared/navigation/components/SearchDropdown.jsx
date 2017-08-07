import React, { Component } from "react";
import { NavDropdown, MenuItem } from "react-bootstrap";
import { RootCloseWrapper } from "react-overlays";

class SearchDropdown extends Component {
  constructor(props) {
    super(props);
    this.state = { searchTerm: "" };
    this.handleSearchTermChange = this.handleSearchTermChange.bind(this);
    this.triggerSearch = this.triggerSearch.bind(this);
  }

  handleSearchTermChange(ev) {
    ev.preventDefault();
    this.setState({ searchTerm: ev.target.value });
  }

  handleRootClose(ev) {
    console.log(ev);
    // if (ev.key !== "Enter") {
    //   ev.preventDefault();
    // }
    // href={`/search?q=${this.state.searchTerm}`}
  }

  render() {
    return (
      <RootCloseWrapper
        onRootClose={this.handleRootClose}
        event={rootCloseEvent}
      >
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
            <input
              type="text"
              placeholder="Search"
              value={this.state.searchTerm}
              onChange={this.handleSearchTermChange}
            />
          </MenuItem>
        </NavDropdown>
      </RootCloseWrapper>
    );
  }
}

export default SearchDropdown;
