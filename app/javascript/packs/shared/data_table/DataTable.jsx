import React, { Component } from "react";
import PropTypes from "prop-types";
import { BootstrapTable, TableHeaderColumn } from 'react-bootstrap-table';

class DataTable extends Component {
  constructor(props) {
    super(props);
    this.cleanProps = this.cleanProps.bind(this);
    this.displayHeader = this.displayHeader.bind(this);
  }

  cleanProps() {
    // Remove additional props from the props value
    const cleanProps = {...this.props};
    delete cleanProps.columns;
    return cleanProps;
  }

  displayHeader() {
    const orderedCols = [...this.props.columns].sort((a, b) => b.position - a.position);
    return orderedCols.map((col) => {
      return (
        <TableHeaderColumn
          key={col.id}
          dataField={col.textId}
          isKey={col.isKey}
          hidden={!col.visible}
        >
          {col.name}
        </TableHeaderColumn>
      );
    });
  }

  render() {
    return (
      <BootstrapTable {...this.cleanProps()}>
        {this.displayHeader()}
      </BootstrapTable>
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
  ).isRequired
};

export default DataTable;