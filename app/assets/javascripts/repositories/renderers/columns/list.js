/* global dropdownSelector I18n */
/* eslint-disable no-unused-vars */

var ListColumnHelper = (function() {
  function listSelect(select, url, value) {
    var selectedOption = '';
    if (value && value.value) {
      selectedOption = `<option value="${value.value}">${value.label}</option>`;
    }
    return $(`<select
              id="${select}"
              data-placeholder = "${I18n.t('repositories.table.list.select_item')}"
              data-ajax-url = "${url}"
            >${selectedOption}</select>`);
  }

  function listHiddenField(formId, columnId, value) {
    var originalValue = value ? value.value : '';
    return $(`<input form="${formId}"
             type="hidden"
             name="repository_cells[${columnId}]"
             value="${originalValue}"
             data-type="RepositoryListValue">`);
  }

  function initialListEditMode(formId, columnId, cell, value = null) {
    var select = 'list-' + columnId;
    var listUrl = $('.repository-column#' + columnId).data('items-url');
    var $select = listSelect(select, listUrl, value);
    var $hiddenField = listHiddenField(formId, columnId, value);
    cell.html($select).append($hiddenField);
    dropdownSelector.init('#' + select, {
      singleSelect: true,
      selectAppearance: 'simple',
      closeOnSelect: true,
      emptyOptionAjax: true,
      onChange: function() {
        var values = dropdownSelector.getValues('#' + select);
        $hiddenField.val(values);
      }
    });
  }

  return {
    initialListEditMode: initialListEditMode
  };
}());
