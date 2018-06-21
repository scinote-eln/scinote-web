import React, { Component } from "react";
import PropTypes from "prop-types";
import { BootstrapTable, TableHeaderColumn } from "react-bootstrap-table";
import styled from "styled-components";
import { FormattedMessage } from "react-intl";
import {
  WHITE_COLOR,
  COLOR_SILVER_CHALICE,
  COLOR_ALTO,
  COLOR_ALABASTER
} from "../../config/constants/colors";

const StyledBootstrapTable = styled(BootstrapTable)`
  thead {
    background-color: ${COLOR_SILVER_CHALICE};

    > tr > th,
    > tr > td {
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

  td,
  th {
    box-sizing: content-box;
  }

  td {
    overflow-wrap: break-word;
    text-overflow: ellipsis;
    word-break: break-word;
  }

  .react-bs-table-pagination {
    .btn {
      border-radius: 4px;
      margin-left: 10px;
    }
    .dropdown.show {
      display: inline-block !important;
    }
  }

  // fixes issue with dropdown in datatable
  .react-bootstrap-table-dropdown-fix {
    overflow: inherit !important;
  }

  .react-bs-container-body {
    overflow: inherit !important;
  }
`;

class DataTable extends Component {
  static renderShowsTotal(start, to, total) {
    return (
      <span>
        <FormattedMessage
          id="settings_page.shows_total_entries"
          values={{
            start,
            to,
            total
          }}
        />
      </span>
    );
  }

  static cleanColumnAttributes(col) {
    // Remove additional attributes from the columns
    const {
      id,
      isKey,
      textId,
      name,
      position,
      visible,
      sortable,
      locked,
      width,
      ...cleanCol
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
    const { columns, ...cleanProps } = this.props;
    return cleanProps;
  }

  displayHeader() {
    const orderedCols = this.props.columns.sort(
      (a, b) => a.position - b.position
    );
    return orderedCols.map(col => (
      <TableHeaderColumn
        key={col.id}
        dataField={col.textId}
        isKey={col.isKey}
        hidden={"visible" in col && !col.visible}
        dataSort={col.sortable}
        width={col.width}
        {...DataTable.cleanColumnAttributes(col)}
      >
        {col.name}
      </TableHeaderColumn>
    ));
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
      locked: PropTypes.bool,
      width: PropTypes.string
    })
  ).isRequired,
  data: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default DataTable;
