/* global DragNDropResults */

(function() {
  $('.new-result-assets-buttons')
    .on('click', '.save-result', (event) => {
      DragNDropResults.processResult(event);
    })
    .on('click', '.cancel-new', () => {
      DragNDropResults.destroyAll();
    });

  $('#new-result-assets-select').on('change', '#drag-n-drop-assets', function() {
    DragNDropResults.init(this.files);
  });
}());
