/* global dropdownSelector */
/* eslint-disable no-unused-vars */

var ChecklistColumnHelper = (function() {
  function checklistSelect(select, url) {
    return $(`<select 
              id="${select}"
              data-placeholder = "Select options..."
              data-ajax-url = "${url}"
              data-combine-tags="true"
              data-select-multiple-all-selected="All options"
              data-select-multiple-name="options"
            ></select>`);
  }

  function checklistHiddenField(formId, columnId, value) {
    return $(`<input form="${formId}"
             type="hidden"
             name="repository_cells[${columnId}]"
             value=""
             data-type="RepositoryChecklistValue">`);
  }

  function initialChecklistEditMode(formId, columnId, cell, value) {
    var select = 'checklist-' + columnId;
    var checklistUrl = $('.repository-column#' + columnId).data('items-url');
    var $select = checklistSelect(select, checklistUrl);
    var $hiddenField = checklistHiddenField(formId, columnId, value)
    cell.html($select).append($hiddenField);
    dropdownSelector.init('#' + select, {
      noEmptyOption: true,
      optionClass: 'checkbox-icon',
      selectAppearance: 'simple',
      onChange: function() {
        var values = JSON.stringify(dropdownSelector.getValues('#' + select));
        $hiddenField.val(values)
      }
    });
  }

  return {
    initialChecklistEditMode: initialChecklistEditMode
  };
}());
