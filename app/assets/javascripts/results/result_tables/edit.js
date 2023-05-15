/* global Results */

(function() {
  $('.edit-result-tables-buttons').on('click', '.save-result', (event) => {
    Results.processResult(event, Results.ResultTypeEnum.TABLE);
  });
}());
