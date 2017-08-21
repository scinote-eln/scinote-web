import React, { Component } from "react";
import PropTypes from "prop-types";
import { BootstrapTable, TableHeaderColumn } from 'react-bootstrap-table';

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
    const orderedCols = [...this.props.columns].sort((a, b) => a.position - b.position);
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
  ).isRequired,
  data: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default DataTable;