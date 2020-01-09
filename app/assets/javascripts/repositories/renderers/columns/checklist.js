/* global dropdownSelector I18n */
/* eslint-disable no-unused-vars */

var ChecklistColumnHelper = (function() {
  function checklistSelect(select, url, values) {
    var selectedOptions = '';
    if (values) {
      $.each(values, function(i, option) {
        selectedOptions += `<option value="${option.value}">${option.label}</option>`;
      });
    }
    return $(`<select 
              id="${select}"
              data-placeholder = "${I18n.t('repositories.table.checklist.set_checklist')}"
              data-ajax-url = "${url}"
              data-combine-tags="true"
              data-select-multiple-all-selected="${I18n.t('libraries.manange_modal_column.checklist_type.all_options')}"
              data-select-multiple-name="${I18n.t('libraries.manange_modal_column.checklist_type.multiple_options')}"
            >${selectedOptions}</select>`);
  }

  function checklistHiddenField(formId, columnId, values) {
    var idList = [];
    if (values) {
      $.each(values, function(i, option) {
        idList.push(option.value);
      });
    } else {
      idList = '';
    }
    return $(`<input form="${formId}"
             type="hidden"
             name="repository_cells[${columnId}]"
             value="${JSON.stringify(idList)}"
             data-type="RepositoryChecklistValue">`);
  }

  function initialChecklistEditMode(formId, columnId, cell, values) {
    var select = 'checklist-' + columnId;
    var checklistUrl = $('.repository-column#' + columnId).data('items-url');
    var $select = checklistSelect(select, checklistUrl, values);
    var $hiddenField = checklistHiddenField(formId, columnId, values);
    cell.html($select).append($hiddenField);
    dropdownSelector.init('#' + select, {
      noEmptyOption: true,
      optionClass: 'checkbox-icon',
      selectAppearance: 'simple',
      onChange: function() {
        $hiddenField.val(JSON.stringify(dropdownSelector.getValues('#' + select)));
      }
    });
  }

  return {
    initialChecklistEditMode: initialChecklistEditMode
  };
}());
