$.fn.dataTable.render.editRowName = function(formId, cell) {
  let $cell = $(cell.node());
  let text = $cell.find('a').first().text();

  $cell.html(`
    <div class="form-group">
      <input class="form-control editing"
             form="${formId}"
             type="text"
             name="repository_row_name"
             value="${text}"
             data-type="RowName">
    </div>
  `);
};

$.fn.dataTable.render.editRepositoryAssetValue = function(formId, columnId, cell) {
  return '';
};

$.fn.dataTable.render.editRepositoryTextValue = function(formId, columnId, cell) {
  SmartAnnotation.init(cell);
  return '';
};

$.fn.dataTable.render.editRepositoryListValue = function(formId, columnId, cell) {
  return '';
};

$.fn.dataTable.render.editRepositoryStatusValue = function(formId, columnId, cell) {
  return '';
};
