/* global GLOBAL_CONSTANTS */
/* eslint-disable no-unused-vars */
var RepositoryListColumnType = (function() {
  var manageModal = '#manageRepositoryColumn';

  function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
  }

  function textToItems(text, delimiter) {
    var res = [];
    var definedDelimiters = {
      return: '\n',
      comma: ',',
      semicolon: ';',
      pipe: '|',
      space: ' '
    };

    var delimiters = []
    if (delimiter === 'auto') {
      delimiters = ['\n', ',', ';', '|', ' '];
    } else {
      delimiters.push(definedDelimiters[delimiter]);
    }

    $.each(delimiters, (index, currentDelimiter) => {
      res = text.trim().split(currentDelimiter);
      if (res.length > 1) {
        return false;
      }
    });

    res = res.filter(Boolean).filter(onlyUnique);

    $.each(res, (index, option) => {
      res[index] = option.slice(0, GLOBAL_CONSTANTS.NAME_MAX_LENGTH);
    });
    return res;
  }

  function drawDropdownPreview(items) {
    var $manageModal = $(manageModal);
    var $dropdownPreview = $manageModal.find('.dropdown-preview select');
    $('option', $dropdownPreview).remove();
    $.each(items, function(i, item) {
      $dropdownPreview.append($('<option>', {
        value: item,
        text: item
      }));
    });
  }

  function initDropdownItemsTextArea() {
    var $manageModal = $(manageModal);
    var listItemsTextarea = '[data-column-type="RepositoryListValue"] #list-items-textarea';
    var dropdownDelimiter = 'select#delimiter';

    $manageModal.off('change keyup paste', listItemsTextarea).on('change keyup paste', listItemsTextarea, function() {
      var items = textToItems($(listItemsTextarea).val(), $(dropdownDelimiter).val());
      drawDropdownPreview(items);
      $('#dropdown_options').val(items);
    });

    $manageModal.off('change', dropdownDelimiter).on('change', dropdownDelimiter, function() {
      var items = textToItems($(listItemsTextarea).val(), $(dropdownDelimiter).val());
      drawDropdownPreview(items);
      $('#dropdown_options').val(items);
    });
  }

  return {
    init: () => {
      initDropdownItemsTextArea();
    }
  };
}());
