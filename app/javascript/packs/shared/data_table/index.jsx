import React, { Component } from "react";
import PropTypes from "prop-types";
import { BootstrapTable, TableHeaderColumn } from 'react-bootstrap-table';
import styled from "styled-components";
import {
  WHITE_COLOR,
  COLOR_GRAY,
  COLOR_ALTO,
  COLOR_ALABASTER
} from "../../app/constants/colors";

const StyledBootstrapTable = styled(BootstrapTable)`
  thead {
    background-color: ${COLOR_GRAY};

    > tr > th,
    >tr > td {
      padding: 6px;
      padding-right: 30px;
    }

    > tr > th {
      border-bottom: 2px solid ${COLOR_ALTO};
      border-bottom-width: 0;
      border-left: 2px solid ${COLOR_ALABASTER};
      color: ${WHITE_COLOR};
      font-weight: normal;
      vertical-align: bottom;

      &:first-child {
        border-left: none;
      }
    }
  }

  td, th {
    box-sizing: content-box;
  }

  td {
    overflow-wrap: break-word;
    text-overflow: ellipsis;
    word-break: break-word;
  }
`;

class DataTable extends Component {
  static cleanColumnAttributes(col) {
    // Remove additional attributes from the columns
    const {
      id, isKey, textId, name, position, visible,
      sortable, locked, ...cleanCol
    } = col;
    return cleanCol;
  }

  constructor(props) {
    super(props);
    this.cleanProps = this.cleanProps.bind(this);
    this.displayHeader = this.displayHeader.bind(this);
  }

  cleanProps() {
    // Remove additional props from the props value
    const {columns, ...cleanProps} = this.props;
    return cleanProps;
  }


  displayHeader() {
    const orderedCols = this.props.columns.sort((a, b) => a.position - b.position);
    return orderedCols.map((col) =>
      <TableHeaderColumn
        key={col.id}
        dataField={col.textId}
        isKey={col.isKey}
        hidden={('visible' in col) && !col.visible}
        dataSort={col.sortable}
        {...DataTable.cleanColumnAttributes(col)}
      >
        {col.name}
      </TableHeaderColumn>
    );
  }

  render() {
    return (
      <StyledBootstrapTable {...this.cleanProps()}>
        {this.displayHeader()}
      </StyledBootstrapTable>
    );
  }
}

DataTable.propTypes = {
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
  data: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default DataTable;
