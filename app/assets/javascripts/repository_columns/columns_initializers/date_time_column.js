/* eslint-disable no-unused-vars */
var RepositoryDateTimeColumnType = (function() {
  return {
    init: () => {},
    checkValidation: () => {
      return true;
    },
    loadParams: () => {
      var isRange = $('#datetime-range').is(':checked');
      var columnType = $('#repository-column-data-type').val();
      if (isRange) {
        columnType = columnType.replace('Value', 'RangeValue');
      }
      return { column_type: columnType };
    }
  };
}());
