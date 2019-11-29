/* global dropdownSelector */
/* eslint-disable no-unused-vars */

var List = (function() {
  function listItemDropdown(options, currentValue, columnId, formId) {
    var html = `<select class="form-control selectpicker repository-dropdown"
                data-abs-min-length="2" data-live-search="true" from="${formId}"
                data-container="body" column_id="${columnId}">
                <option value="-1"></option>`;
    $.each(options, function(index, value) {
      var selected = (currentValue === value[1]) ? 'selected' : '';
      html += '<option value="' + value[0] + '" ' + selected + '>';
      html += value[1] + '</option>';
    });
    html += '</select>';
    return html;
  }

  function initialListItemsRequest(columnId, currentValue, formId, url) {
    var massageResponse = [];
    $.ajax({
      url: url,
      type: 'POST',
      dataType: 'json',
      async: false,
      data: {
        column_id: columnId
      }
    }).done(function(data) {
      $.each(data.list_items, function(index, el) {
        massageResponse.push([el.id, el.data]);
      });
    });
    return listItemDropdown(massageResponse, currentValue, columnId, formId);
  }

  function initSelectPicker($select, $hiddenField) {
    dropdownSelector.init($select, {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      onChange: function() {
        $hiddenField.val(dropdownSelector.getValues($select));
      }
    });
  }

  return {
    initialListItemsRequest: initialListItemsRequest,
    initSelectPicker: initSelectPicker
  };
}());
