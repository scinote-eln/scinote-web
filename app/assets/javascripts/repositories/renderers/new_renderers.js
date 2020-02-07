/*
global ListColumnHelper ChecklistColumnHelper StatusColumnHelper SmartAnnotation I18n
AssetColumnHelper DateTimeHelper
*/

$.fn.dataTable.render.newRowName = function(formId, $cell) {
  $cell.html(`
    <div class="sci-input-container text-field error-icon">
      <input class="sci-input-field"
             form="${formId}"
             type="text"
             name="repository_row[name]"
             value=""
             placeholder="${I18n.t('repositories.table.enter_row_name')}"
             data-type="RowName">
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

  SmartAnnotation.init($cell.find('input'));
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
  let decimals = $header.data('metadata-decimals');

  $cell.html(`
    <div class="sci-input-container text-field  error-icon">
      <input class="sci-input-field"
             form="${formId}"
             type="text"
             oninput="this.value = this.value.replace(/[^0-9.]/g, '');
                      this.value = this.value.match(/^\\d*(\\.\\d{0,${decimals}})?/)[0];"
             name="repository_cells[${columnId}]"
             value=""
             placeholder="${I18n.t('repositories.table.number.enter_number')}"
             data-type="RepositoryNumberValue">
    </div>`);
};

$.fn.dataTable.render.newRepositoryDateTimeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, '', 'RepositoryDateTimeValue');
};

$.fn.dataTable.render.newRepositoryTimeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'timeonly', 'RepositoryTimeValue');
};

$.fn.dataTable.render.newRepositoryDateValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'dateonly', 'RepositoryDateValue');
};

$.fn.dataTable.render.newRepositoryDateTimeRangeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, '', 'RepositoryDateTimeRangeValue');
};

$.fn.dataTable.render.newRepositoryDateRangeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'dateonly', 'RepositoryDateRangeValue');
};

$.fn.dataTable.render.newRepositoryTimeRangeValue = function(formId, columnId, $cell) {
  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'timeonly', 'RepositoryTimeRangeValue');
};
