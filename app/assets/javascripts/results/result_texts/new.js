/* global Results */

(function() {
  $('.new-result-texts-buttons').on('click', '.save-result', (event) => {
    Results.processResult(event, Results.ResultTypeEnum.TEXT);
  });
}());
