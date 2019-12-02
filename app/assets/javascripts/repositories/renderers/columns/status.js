/* global dropdownSelector */
/* eslint-disable no-unused-vars */

var Status = (function() {
  function statusItemDropdown(options, currentValueId, columnId, formId) {
    var html = `<select class="form-control selectpicker repository-dropdown"
                data-abs-min-length="2" data-live-search="true" from="${formId}"
                data-container="body" column_id="${columnId}">
                <option value="-1"></option>`;
    $.each(options, function(index, value) {
      var selected = (parseInt(currentValueId, 10) === value[0]) ? 'selected' : '';
      html += `<option value="${value[0]}" ${selected}>${value[2]} ${value[1]}</option>`;
    });
    html += '</select>';
    return html;
  }

  function initialStatusItemsRequest(columnId, currentValue, formId, url) {
    var massageResponse = [];
    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      async: false,
      data: {
        column_id: columnId
      }
    }).done(function(data) {
      $.each(data.status_items, function(index, el) {
        massageResponse.push([el.id, el.status, el.icon]);
      });
    });
    return statusItemDropdown(massageResponse, currentValue, columnId, formId);
  }

  function initStatusSelectPicker($select, $hiddenField) {
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
    initialStatusItemsRequest: initialStatusItemsRequest,
    initStatusSelectPicker: initStatusSelectPicker
  };
}());
