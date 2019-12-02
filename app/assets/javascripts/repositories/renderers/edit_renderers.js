/* global List Status SmartAnnotation*/

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
  let $cell = $(cell.node());
  let text = $cell.text();

  $cell.html(`
    <div class="form-group">
      <input class="form-control editing"
             form="${formId}"
             type="text"
             name="repository_cells[${columnId}]"
             value="${text}"
             data-type="RepositoryTextValue">
    </div>`);

  SmartAnnotation.init($cell.find('input'));
};

$.fn.dataTable.render.editRepositoryListValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());
  let currentValueId = $cell.find('.list-label').attr('data-value-id');
  let url = $cell.closest('table').data('list-items-path');
  let hiddenField = `
    <input form="${formId}"
           type="hidden"
           name="repository_cells[${columnId}]"
           value=""
           data-type="RepositoryListValue">`;

  $cell.html(hiddenField + List.initialListItemsRequest(columnId, currentValueId, formId, url));

  List.initSelectPicker($cell.find('select'), $cell.find(`[name='repository_cells[${columnId}]']`));
};

$.fn.dataTable.render.editRepositoryStatusValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());
  let currentValueId = $cell.find('.status-label').attr('data-value-id');

  let url = $cell.closest('table').data('status-items-path');
  let hiddenField = `
    <input form="${formId}"
           type="hidden"
           name="repository_cells[${columnId}]"
           value=""
           data-type="RepositoryStatusValue">`;

  $cell.html(hiddenField + Status.initialStatusItemsRequest(columnId, currentValueId, formId, url));

  Status.initStatusSelectPicker($cell.find('select'), $cell.find(`[name='repository_cells[${columnId}]']`));
};

$.fn.dataTable.render.editRepositoryDateTimeValue = function(formId, columnId, cell) {
  return '';
};

$.fn.dataTable.render.editRepositoryDateValue = function(formId, columnId, cell) {
  return '';
};

$.fn.dataTable.render.editRepositoryTimeValue = function(formId, columnId, cell) {
  return '';
};

$.fn.dataTable.render.editRepositoryDateTimeRangeValue = function(formId, columnId, cell) {
  return '';
};

$.fn.dataTable.render.editRepositoryDateRangeValue = function(formId, columnId, cell) {
  return '';
};

$.fn.dataTable.render.editRepositoryTimeRangeValue = function(formId, columnId, cell) {
  return '';
};
