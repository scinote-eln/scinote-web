/* global Results */

(function() {
  $('.new-result-tables-buttons').on('click', '.save-result', (event) => {
    Results.processResult(event, Results.ResultTypeEnum.TABLE);
  });
}());
