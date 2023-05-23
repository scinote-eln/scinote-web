/* global Handsontable */
window.onload = function() {
  var tables = document.getElementsByClassName('hot-table-container');
  var tableVals = document.getElementsByClassName('hot-table-contents');

  for (let i = 0; i < tables.length; i += 1) {
    tables[i].innerHTML = '';
    new Handsontable(tables[i], {
      data: JSON.parse(tableVals[i].value).data,
      rowHeaders: true,
      colHeaders: true,
      filters: true,
      dropdownMenu: true,
      formulas: true
    });
  }
};
