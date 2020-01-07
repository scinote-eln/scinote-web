/*
global ListColumnHelper ChecklistColumnHelper StatusColumnHelper SmartAnnotation I18n
GLOBAL_CONSTANTS DateTimeHelper
*/

$.fn.dataTable.render.editRowName = function(formId, cell) {
  let $cell = $(cell.node());
  let text = $cell.find('a').first().text();

  $cell.html(`
    <div class="form-group">
      <input class="form-control editing"
             form="${formId}"
             type="text"
             name="repository_row[name]"
             value="${text}"
             data-type="RowName">
    </div>
  `);
};

$.fn.dataTable.render.editRepositoryAssetValue = function(formId, columnId, cell) {
  let $cell = $(cell.node());
  let empty = $cell.is(':empty');
  let fileName = $cell.find('a.file-preview-link').text();

  $cell.html(`
    <div class="file-editing">
      <div class="file-hidden-field-container hidden"></div>
      <input class=""
             id="repository_file_${columnId}"
             form="${formId}"
             type="file"
             data-col-id="${columnId}"
             data-is-empty="${empty}"
             value=""
             data-type="RepositoryAssetValue">
      <div class="file-upload-button ${empty ? 'new-file' : ''}">
        <label for="repository_file_${columnId}">${I18n.t('repositories.table.assets.select_file_btn', { max_size: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB })}</label>
        <span class="icon"><i class="fas fa-paperclip"></i></span><span class="label-asset">${fileName}</span>
        <span class="delete-action fas fa-trash"> </span>
      </div>
    </div>`);
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
      label: iconElement.text() + ' ' + currentElement.text()
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
  let decimals = Number($header.data('metadata-decimals'));
  let number = parseFloat(Number($cell.text()).toFixed(decimals));

  $cell.html(`
    <div class="form-group">
      <input class="form-control editing"
             form="${formId}"
             type="number"
             name="repository_cells[${columnId}]"
             value="${number}"
             onchange="if (this.value !== '') { this.value = parseFloat(Number(this.value).toFixed(${decimals})); }"
             data-type="RepositoryNumberValue">
    </div>`);
};
