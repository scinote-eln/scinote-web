/* global dropdownSelector I18n twemoji */
/* eslint-disable no-unused-vars */

var StatusColumnHelper = (function() {
  function statusSelect(select, url, value) {
    var selectedOption = '';
    if (value && value.value) {
      selectedOption = `<option value="${value.value}">${value.label}</option>`;
    }

    return $(`<select
              id="${select}"
              data-placeholder = "${I18n.t('repositories.table.status.set_status')}"
              data-ajax-url = "${url}"
            >${selectedOption}</select>`);
  }

  function statusHiddenField(formId, columnId, value) {
    var originalValue = value ? value.value : '';
    return $(`<input form="${formId}"
             type="hidden"
             name="repository_cells[${columnId}]"
             value="${originalValue}"
             data-type="RepositoryStatusValue">`);
  }

  function initialStatusEditMode(formId, columnId, cell, value = null) {
    var select = 'status-list-' + columnId;
    var listUrl = $('.repository-column#' + columnId).data('items-url');
    var $select = statusSelect(select, listUrl, value);
    var $hiddenField = statusHiddenField(formId, columnId, value);
    cell.html($select).append($hiddenField);
    dropdownSelector.init('#' + select, {
      singleSelect: true,
      selectAppearance: 'simple',
      closeOnSelect: true,
      emptyOptionAjax: true,
      onChange: () => {
        var values = dropdownSelector.getValues('#' + select);
        $hiddenField.val(values);
      },
      optionClass: 'emoji-status',
      optionLabel: (data) => {
        return twemoji.parse(data.label);
      },
      tagClass: 'emoji-status',
      tagLabel: (data) => {
        return twemoji.parse(data.label);
      }
    });
  }

  return {
    initialStatusEditMode: initialStatusEditMode
  };
}());
