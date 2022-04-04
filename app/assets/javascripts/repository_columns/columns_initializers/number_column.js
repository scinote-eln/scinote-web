/* eslint-disable no-unused-vars */
var RepositoryNumberColumnType = (function() {
  return {
    init: () => {},
    checkValidation: () => {
      return true;
    },
    loadParams: () => {
      var decimals = $('.number-column-type #decimals').val();
      return { metadata: { decimals: decimals } };
    }
  };
}());
