/* eslint-disable no-unused-vars */
var RepositoryDateColumnType = (function() {
  return {
    init: () => {},
    checkValidation: () => {
      return true;
    },
    loadParams: () => {
      var isRange = $('#date-range').is(':checked');
      var columnType = $('#repository-column-data-type').val();
      if (isRange) {
        columnType = columnType.replace('Value', 'RangeValue');
      }
      return { column_type: columnType };
    }
  };
}());
