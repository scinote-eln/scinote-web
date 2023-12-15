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
             value=""
             placeholder="${I18n.t('repositories.table.enter_row_name')}"
             data-type="RowName"
             data-e2e="e2e-IF-invInventoryEditItemTR-name">
    </div>
  `);
  $cell.find('input').val(text);
};

$.fn.dataTable.render.editRepositoryAssetValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());
  AssetColumnHelper.renderCell($cell, formId, columnId);
};

$.fn.dataTable.render.editRepositoryTextValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());
  let text = $cell.find('.text-value').data('edit-value') || '';
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
  $cell.find('input').val(text);
  SmartAnnotation.init($cell.find('input'), true);
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

  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'datetime', 'RepositoryDateTimeValue');
};

$.fn.dataTable.render.editRepositoryDateValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'date', 'RepositoryDateValue');
};

$.fn.dataTable.render.editRepositoryTimeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeEditMode(formId, columnId, $cell, 'time', 'RepositoryTimeValue');
};

$.fn.dataTable.render.editRepositoryDateTimeRangeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'datetime', 'RepositoryDateTimeRangeValue');
};

$.fn.dataTable.render.editRepositoryDateRangeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'date', 'RepositoryDateRangeValue');
};

$.fn.dataTable.render.editRepositoryTimeRangeValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());

  DateTimeHelper.initDateTimeRangeEditMode(formId, columnId, $cell, 'time', 'RepositoryTimeRangeValue');
};

$.fn.dataTable.render.editRepositoryChecklistValue = function(formId, columnId, cell) {
  var $cell = $(cell.node());
  var currentValue = $cell.find('.checklist-options').data('checklist-items');
  ChecklistColumnHelper.initialChecklistEditMode(formId, columnId, $cell, currentValue);
};

$.fn.dataTable.render.editRepositoryNumberValue = function(formId, columnId, cell, $header) {
  const $cell = $(cell.node());
  const decimals = $header.data('metadata-decimals');
  let number = $cell.find('.number-value').data('value');
  if (!number) number = '';

  let $input = $('<input>', {
    class: 'sci-input-field',
    form: formId,
    type: 'text',
    name: 'repository_cells[' + columnId + ']',
    placeholder: I18n.t('repositories.table.number.enter_number'),
    value: number,
    'data-type': 'RepositoryNumberValue'
  });

  $input.on('input', function() {
    const regexp = decimals === 0 ? /[^0-9]/g : /[^0-9.]/g;
    const decimalsRegex = new RegExp(`^\\d*(\\.\\d{0,${decimals}})?`);
    let value = this.value;
    value = value.replace(regexp, '');
    value = value.match(decimalsRegex)[0];
    this.value = value;
  });

  let $div = $('<div>', {
    class: 'sci-input-container text-field error-icon'
  }).append($input);

  $cell.html($div);
};

$.fn.dataTable.render.editRepositoryStockValue = function(formId, columnId, cell) {
  return cell.node();
};

$.fn.dataTable.render.editRepositoryStockConsumptionValue = function(formId, columnId, cell) {
  return cell.node();
};
