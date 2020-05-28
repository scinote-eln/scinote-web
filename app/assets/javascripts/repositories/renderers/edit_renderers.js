/*
global ListColumnHelper ChecklistColumnHelper StatusColumnHelper SmartAnnotation I18n
DateTimeHelper AssetColumnHelper
*/

$.fn.dataTable.render.editRowName = function(formId, cell) {
  let $cell = $(cell.node());
  let text = $cell.find('a').first().text();

  $cell.html(`
    <div class="sci-input-container text-field error-icon">
      <input class="sci-input-field"
             form="${formId}"
             type="text"
             name="repository_row[name]"
             value="${text}"
             placeholder="${I18n.t('repositories.table.enter_row_name')}"
             data-type="RowName">
    </div>
  `);
};

$.fn.dataTable.render.editRepositoryAssetValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());
  AssetColumnHelper.renderCell($cell, formId, columnId);
};

$.fn.dataTable.render.editRepositoryTextValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());
  let text = $cell.text();

  $cell.html(`
    <div class="sci-input-container text-field  error-icon">
      <input class="sci-input-field"
             form="${formId}"
             type="text"
             name="repository_cells[${columnId}]"
             value="${text}"
             placeholder="${I18n.t('repositories.table.text.enter_text')}"
             data-type="RepositoryTextValue">
    </div>`);

  SmartAnnotation.init($cell.find('input'));
};

$.fn.dataTable.render.editRepositoryListValue = function(formId, columnId, cell) {
  var $cell = $(cell.node());
  var currentElement = $cell.find('.list-label');
  var currentValue = null;
  if (currentElement.length) {
    currentValue = {
      value: currentElement.attr('data-value-id'),
      label: currentElement.text()
    };
  }

  ListColumnHelper.initialListEditMode(formId, columnId, $cell, currentValue);
};

$.fn.dataTable.render.editRepositoryStatusValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());
  var currentElement = $cell.find('.status-label');
  var iconElement = $cell.find('.repository-status-value-icon');
  var currentValue = null;
  if (currentElement.length) {
    currentValue = {
      value: currentElement.attr('data-value-id'),
      label: iconElement.find('img').attr('alt') + ' ' + currentElement.text()
    };
  }

  StatusColumnHelper.initialStatusEditMode(formId, columnId, $cell, currentValue);
};

$.fn.dataTable.render.editRepositoryDateTimeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, '', 'RepositoryDateTimeValue');
};

$.fn.dataTable.render.editRepositoryDateValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'dateonly', 'RepositoryDateValue');
};

$.fn.dataTable.render.editRepositoryTimeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'timeonly', 'RepositoryTimeValue');
};

$.fn.dataTable.render.editRepositoryDateTimeRangeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, '', 'RepositoryDateTimeRangeValue');
};

$.fn.dataTable.render.editRepositoryDateRangeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'dateonly', 'RepositoryDateRangeValue');
};

$.fn.dataTable.render.editRepositoryTimeRangeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'timeonly', 'RepositoryTimeRangeValue');
};

$.fn.dataTable.render.editRepositoryChecklistValue = function(formId, columnId, cell) {
  var $cell = $(cell.node());
  var currentValue = $cell.find('.checklist-options').data('checklist-items');
  ChecklistColumnHelper.initialChecklistEditMode(formId, columnId, $cell, currentValue);
};

$.fn.dataTable.render.editRepositoryNumberValue = function(formId, columnId, cell, $header) {
  let $cell = $(cell.node());
  let decimals = $header.data('metadata-decimals');
  let number = $cell.find('.number-value').data('value');

  if (!number) number = '';

  $cell.html(`
    <div class="sci-input-container text-field  error-icon">
      <input class="sci-input-field"
             form="${formId}"
             type="text"
             oninput="regexp = ${decimals} === 0 ? /[^0-9]/g : /[^0-9.]/g
                      this.value = this.value.replace(regexp, '');
                      this.value = this.value.match(/^\\d*(\\.\\d{0,${decimals}})?/)[0];"
             name="repository_cells[${columnId}]"
             placeholder="${I18n.t('repositories.table.number.enter_number')}"
             value="${number}"
             data-type="RepositoryNumberValue">
    </div>`);
};
