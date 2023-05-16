/* global Results */

(function() {
  $('.edit-result-assets-buttons').on('click', '.save-result', (event) => {
    Results.processResult(event, Results.ResultTypeEnum.FILE);
  });
}());
