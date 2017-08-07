import React, { Component } from "react";
import { NavDropdown, FormControl } from "react-bootstrap";

class SearchDropdown extends Component {
  constructor(props) {
    super(props);
    this.state = { searchTerm: "" };
    this.handleSearchTermChange = this.handleSearchTermChange.bind(this);
    this.handleSelect = this.handleSelect.bind(this);
  }

  handleSearchTermChange(ev) {
    ev.preventDefault();
    console.log("change");
    this.setState({ searchTerm: ev.target.value });
  }

  handleSelect(ev) {
    console.log(ev);
    ev.preventDefault();
  }

  render() {
    return (
      <NavDropdown
        noCaret
        title={<span className="glyphicon glyphicon-search" />}
        id="search-dropdown"
      >
        <li role="presentation" onClick={ev => ev.preventDefault()}>
          <FormControl
              ref={c => { this.input = c; }}
              type="text"
              placeholder="Search"
              onChange={this.handleSearchTermChange}
              value={this.state.searchTerm} />
        </li>
      </NavDropdown>
    );
  }
}

export default SearchDropdown;
