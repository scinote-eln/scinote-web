/*
global ListColumnHelper ChecklistColumnHelper StatusColumnHelper SmartAnnotation I18n
AssetColumnHelper DateTimeHelper
*/

$.fn.dataTable.render.newRowName = function(formId, $cell) {
  $cell.html(`
    <div class="sci-input-container text-field error-icon">
      <input class="sci-input-field"
             id="newRepoNameField"
             form="${formId}"
             type="text"
             name="repository_row[name]"
             value=""
             placeholder="${I18n.t('repositories.table.enter_row_name')}"
             data-type="RowName"
             data-e2e="e2e-IF-invInventoryNewItemTR-name">
    </div>
  `);
};

$.fn.dataTable.render.newRepositoryAssetValue = function(formId, columnId, $cell) {
  AssetColumnHelper.renderCell($cell, formId, columnId);
};

$.fn.dataTable.render.newRepositoryTextValue = function(formId, columnId, $cell) {
  $cell.html(`
    <div class="sci-input-container text-field  error-icon">
      <input class="sci-input-field"
             form="${formId}"
             type="text"
             name="repository_cells[${columnId}]"
             value=""
             placeholder="${I18n.t('repositories.table.text.enter_text')}"
             data-type="RepositoryTextValue">
    </div>`);

  SmartAnnotation.init($cell.find('input'), false);
};

$.fn.dataTable.render.newRepositoryListValue = function(formId, columnId, $cell) {
  ListColumnHelper.initialListEditMode(formId, columnId, $cell);
};

$.fn.dataTable.render.newRepositoryStatusValue = function(formId, columnId, $cell) {
  StatusColumnHelper.initialStatusEditMode(formId, columnId, $cell);
};

$.fn.dataTable.render.newRepositoryChecklistValue = function(formId, columnId, $cell) {
  ChecklistColumnHelper.initialChecklistEditMode(formId, columnId, $cell);
};

$.fn.dataTable.render.newRepositoryNumberValue = function(formId, columnId, $cell, $header) {
  const decimals = $header.data('metadata-decimals');

  let $input = $('<input>', {
    class: 'sci-input-field',
    form: formId,
    type: 'text',
    name: 'repository_cells[' + columnId + ']',
    value: '',
    placeholder: I18n.t('repositories.table.number.enter_number'),
    'data-type': 'RepositoryNumberValue'
  });

  $input.on('input', function() {
    const decimalsRegex = new RegExp(`^\\d*(\\.\\d{0,${decimals}})?`);
    let value = this.value;
    value = value.replace(/[^0-9.]/g, '');
    value = value.match(decimalsRegex)[0];
    this.value = value;
  });

  let $div = $('<div>', {
    class: 'sci-input-container text-field error-icon'
  }).append($input);

  $cell.html($div);
};

$.fn.dataTable.render.newRepositoryDateTimeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'datetime', 'RepositoryDateTimeValue');
};

$.fn.dataTable.render.newRepositoryTimeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'time', 'RepositoryTimeValue');
};

$.fn.dataTable.render.newRepositoryDateValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'date', 'RepositoryDateValue');
};

$.fn.dataTable.render.newRepositoryDateTimeRangeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'datetime', 'RepositoryDateTimeRangeValue');
};

$.fn.dataTable.render.newRepositoryDateRangeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'date', 'RepositoryDateRangeValue');
};

$.fn.dataTable.render.newRepositoryTimeRangeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'time', 'RepositoryTimeRangeValue');
};

$.fn.dataTable.render.newRepositoryStockValue = function() {
  return '';
};
