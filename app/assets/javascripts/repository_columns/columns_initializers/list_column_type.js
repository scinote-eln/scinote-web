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

  function refreshCounter(number) {
    var $manageModal = $(manageModal);
    $manageModal.find('.list-items-count').html(number);

    if (number > GLOBAL_CONSTANTS.REPOSITORY_LIST_ITEMS_PER_COLUMN) {
      $manageModal.find('.limit-counter-container').addClass('error-to-many-items');
      $manageModal.find('button[data-action="save"]').prop('disabled', true);
    } else {
      $manageModal.find('.limit-counter-container').removeClass('error-to-many-items');
      $manageModal.find('button[data-action="save"]').prop('disabled', false);
    }
  }

  function refreshPreviewDropdownList() {
    var listItemsTextarea = '[data-column-type="RepositoryListValue"] #list-items-textarea';
    var dropdownDelimiter = 'select#delimiter';

    var items = textToItems($(listItemsTextarea).val(), $(dropdownDelimiter).val());
    var hashItems = [];
    drawDropdownPreview(items);
    refreshCounter(items.length);

    $.each(items, (index, option) => {
      hashItems.push({ data: option });
    });

    $('#dropdown_options').val(JSON.stringify(hashItems));
  }

  function initDropdownItemsTextArea() {
    var $manageModal = $(manageModal);
    var listItemsTextarea = '[data-column-type="RepositoryListValue"] #list-items-textarea';
    var dropdownDelimiter = 'select#delimiter';
    var columnNameInput = 'input#repository-column-name';

    $manageModal.off('change keyup paste', listItemsTextarea).on('change keyup paste', listItemsTextarea, function() {
      refreshPreviewDropdownList();
    });

    $manageModal.off('change', dropdownDelimiter).on('change', dropdownDelimiter, function() {
      refreshPreviewDropdownList();
    });

    $manageModal.off('columnModal::partialLoaded').on('columnModal::partialLoaded', function() {
      refreshPreviewDropdownList();
    });

    $manageModal.off('keyup change', columnNameInput).on('keyup change', columnNameInput, function() {
      $manageModal.find('.preview-label').html($manageModal.find(columnNameInput).val());
    });
  }

  return {
    init: () => {
      initDropdownItemsTextArea();
    }
  };
}());
