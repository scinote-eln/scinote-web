import React, { Component } from "react";
import PropTypes from "prop-types";
import ReactDataGrid from 'react-data-grid';
import styled from "styled-components";
import {
  WHITE_COLOR,
  COLOR_SILVER_CHALICE
} from "../../config/constants/colors";

const StyledReactDataGrid = styled(ReactDataGrid)`
  background-color: inherit;

  .react-grid-Grid {
    background-color: inherit;
  }

  .react-grid-Header {
    .react-grid-HeaderCell {
      background-color: ${COLOR_SILVER_CHALICE};

      color: ${WHITE_COLOR};
      font-weight: normal;
      vertical-align: bottom;

      &:first-child {
        border-left: none;
      }
    }
  }

  .react-grid-Canvas {
    background-color: inherit;
  }
`;

class DataGrid extends Component {
  constructor(props) {
    super(props);
    this.cleanProps = this.cleanProps.bind(this);
    this.transformColumns = this.transformColumns.bind(this);
    this.setupDefaultProps = this.setupDefaultProps.bind(this);

    this.transformColumns();
    this.setupDefaultProps();

    // Store the original rows array, and make a copy that
    // can be used for modifying eg.filtering, sorting
    this.state = {
      originalRows: this.props.data,
      rows: this.props.data.slice(0)
    };
  }

  setupDefaultProps() {
    // Setup the default props if they're not provided
    if ('rowGetter' in this.props) {
      this._rowGetter = this.props.rowGetter;
    } else {
      this._rowGetter = ((i) => this.state.rows[i]);
    }
    this._rowGetter = this._rowGetter.bind(this);

    if ('rowsCount' in this.props) {
      this._rowsCount = this.props.rowsCount;
    } else {
      this._rowsCount = this.props.data.length;
    }

    if ('onGridSort' in this.props) {
      this._onGridSort = this.props.onGridSort;
    } else {
      this._onGridSort = ((sortColumn, sortDirection) => {
        const comparer = (a, b) => {
          if (sortDirection === 'ASC') {
            return (a[sortColumn] > b[sortColumn]) ? 1 : -1;
          } else if (sortDirection === 'DESC') {
            return (a[sortColumn] < b[sortColumn]) ? 1 : -1;
          }
          return 0;
        };
        let rows;
        if (sortDirection === 'NONE') {
          rows = this.state.originalRows.slice(0);
        } else {
          rows = this.state.rows.sort(comparer);
        }

        this.setState({ rows });
      });
    }
    this._onGridSort = this._onGridSort.bind(this);
  }

  transformColumns() {
    // Transform columns from the "SciNote" representation into
    // ReactDataGrid-compatible representation
    this._columns =
      this.props.columns
      .sort((a, b) => a.position - b.position)
      .filter((col) => (!('visible' in col) || col.visible))
      .map((col) => ({
        key: col.textId,
        name: col.name,
        locked: col.locked,
        sortable: col.sortable
      }));
  }

  cleanProps() {
    // Remove additional props from the props value
    const {
      columns, rowGetter, rowsCount, ...cleanProps
    } = this.props;
    return cleanProps;
  }

  render() {
    return (
      <StyledReactDataGrid
        columns={this._columns}
        rowGetter={this._rowGetter}
        rowsCount={this._rowsCount}
        onGridSort={this._onGridSort}
        {...this.cleanProps()}
      />
    );
  }
}

DataGrid.propTypes = {
  columns: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      isKey: PropTypes.bool.isRequired,
      textId: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
      position: PropTypes.number.isRequired,
      visible: PropTypes.bool,
      sortable: PropTypes.bool,
      locked: PropTypes.bool
    })
  ).isRequired,
  data: PropTypes.arrayOf(PropTypes.object).isRequired,
  rowGetter: PropTypes.func,
  rowsCount: PropTypes.number,
  onGridSort: PropTypes.func
};

export default DataGrid;
