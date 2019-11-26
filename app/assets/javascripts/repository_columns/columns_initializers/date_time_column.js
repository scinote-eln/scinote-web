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
      return { range: isRange, column_type: columnType };
    }
  };
}());
