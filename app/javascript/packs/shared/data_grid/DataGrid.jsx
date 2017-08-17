import React, { Component } from "react";
import PropTypes from "prop-types";
import ReactDataGrid from 'react-data-grid';

class DataGrid extends Component {
  constructor(props) {
    super(props);
    this.cleanProps = this.cleanProps.bind(this);
    this.transformColumns = this.transformColumns.bind(this);
    this.setupDefaultProps = this.setupDefaultProps.bind(this);

    this.transformColumns();
    this.setupDefaultProps();
  }

  transformColumns() {
    // Transform columns from the "sciNote" representation into
    // ReactDataGrid-compatible representation
    this._columns =
      this.props.columns
      .sort((a, b) => b.position - a.position)
      .filter((col) => col.visible)
      .map((col) => {
        return {
          key: col.textId,
          name: col.name,
          locked: col.locked
        };
      });
  }

  setupDefaultProps() {
    // Setup the default props if they're not provided
    const self = this;

    if ('rowGetter' in this.props) {
      this._rowGetter = this.props.rowGetter;
    } else {
      this._rowGetter = function(i) {
        return this.props.data[i];
      }.bind(this);
    }
    if ('rowsCount' in this.props) {
      this._rowsCount = this.props.rowsCount;
    } else {
      this._rowsCount = this.props.data.length;
    }
  }

  cleanProps() {
    // Remove additional props from the props value
    const cleanProps = {...this.props};
    delete cleanProps.columns;
    delete cleanProps.rowGetter;
    delete cleanProps.rowsCount;
    return cleanProps;
  }

  render() {
    return (
      <ReactDataGrid
        columns={this._columns}
        rowGetter={this._rowGetter}
        rowsCount={this._rowsCount}
        {...this.cleanProps()}
      />
    );
  }
}

DataGrid.propTypes = {
};

export default DataGrid;