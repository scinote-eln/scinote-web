/* global dropdownSelector I18n twemoji */
/* eslint-disable no-unused-vars */

var StatusColumnHelper = (function() {
  function statusSelect(select, url, value) {
    var selectedOption = '';
    var selectObject = $(`<select id="${select}"
                                  data-placeholder = "${I18n.t('repositories.table.status.set_status')}"
                                  data-ajax-url = "${url}" ></select>`);

    if (value && value.value) {
      selectedOption = $(`<option value="${value.value}"></option>`);
      selectedOption.text(value.label);
      selectedOption.appendTo(selectObject);
    }
    return selectObject;
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
    var select = `status-list-${columnId}-${cell.parent()[0].id}`;
    var listUrl = $('.repository-column#' + columnId).data('items-url');
    var $select = statusSelect(select, listUrl, value);
    var $hiddenField = statusHiddenField(formId, columnId, value);
    cell.html($select).append($hiddenField);
    dropdownSelector.init('#' + select, {
      singleSelect: true,
      selectAppearance: 'simple',
      closeOnSelect: true,
      emptyOptionAjax: true,
      labelHTML: true,
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
        var render = $('<div>').html(twemoji.parse(data.label));
        render.find(':not(img)').remove();
        return render.html();
      }
    });
  }

  return {
    initialStatusEditMode: initialStatusEditMode
  };
}());
