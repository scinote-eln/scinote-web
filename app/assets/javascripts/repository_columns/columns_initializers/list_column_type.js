/* global GLOBAL_CONSTANTS  I18n */
/* eslint-disable no-unused-vars */
var RepositoryListColumnType = (function() {
  var manageModal = '#manage-repository-column';

  function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
  }

  function textToItems(text, delimiter) {
    var res = [];
    var usedDelimiter = '';
    var definedDelimiters = {
      return: '\n',
      comma: ',',
      semicolon: ';',
      space: ' '
    };

    var delimiters = [];
    if (delimiter === 'auto') {
      delimiters = ['\n', ',', ';', ' '];
    } else {
      delimiters.push(definedDelimiters[delimiter]);
    }

    $.each(delimiters, (index, currentDelimiter) => {
      res = text.trim().split(currentDelimiter);
      usedDelimiter = Object
        .keys(definedDelimiters)
        .find(key => definedDelimiters[key] === currentDelimiter);

      if (res.length > 1) {
        return false;
      }
      return true;
    });

    res = res.filter(Boolean).filter(onlyUnique);

    $.each(res, (index, option) => {
      res[index] = option.slice(0, GLOBAL_CONSTANTS.NAME_MAX_LENGTH);
    });

    $('select#delimiter').attr('data-used-delimiter', usedDelimiter);
    return res;
  }

  function pluralizeWord(count, noun, suffix = 's') {
    return `${noun}${count !== 1 ? suffix : ''}`;
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

    if (items.length === 0) {
      $dropdownPreview.append($('<option>', {
        value: '',
        text: I18n.t('libraries.manange_modal_column.list_type.dropdown_item_select_option')
      }));
    }
  }

  function refreshCounter(number) {
    var $manageModal = $(manageModal);
    var $counterContainer = $manageModal.find('.limit-counter-container');
    var $btn = $manageModal.find('.column-save-btn');

    $manageModal.find('.list-items-count').html(number).attr('data-count', number);

    if (number >= GLOBAL_CONSTANTS.REPOSITORY_LIST_ITEMS_PER_COLUMN) {
      $counterContainer.addClass('error-to-many-items');
      $btn.addClass('disabled');
    } else {
      $counterContainer.removeClass('error-to-many-items');
      $btn.removeClass('disabled');
    }
  }

  function refreshPreviewDropdownList() {
    var listItemsTextarea = '.list-column-type #list-items-textarea';
    var dropdownDelimiter = '#delimiter';

    var items = textToItems($(listItemsTextarea).val(), $(dropdownDelimiter).val());
    var hashItems = [];
    drawDropdownPreview(items);
    refreshCounter(items.length);

    $.each(items, (index, option) => {
      hashItems.push({ data: option });
    });

    $('#dropdown_options').val(JSON.stringify(hashItems));
    $('.limit-counter-container .items-label').html(pluralizeWord(items.length, 'item'));
  }

  function initDropdownItemsTextArea() {
    var $manageModal = $(manageModal);
    var listItemsTextarea = '.list-column-type #list-items-textarea';
    var dropdownDelimiter = '#delimiter';
    var columnNameInput = '#repository-column-name';

    $manageModal
      .off('change keyup paste', listItemsTextarea)
      .off('change', dropdownDelimiter)
      .off('columnModal::partialLoadedForRepositoryListValue')
      .off('keyup change', columnNameInput)
      .on('change keyup paste', listItemsTextarea, function() {
        refreshPreviewDropdownList();
      })
      .on('change', dropdownDelimiter, function() {
        refreshPreviewDropdownList();
      })
      .on('columnModal::partialLoadedForRepositoryListValue', function() {
        refreshPreviewDropdownList();
      })
      .on('keyup change', columnNameInput, function() {
        $manageModal.find('.preview-label').html($manageModal.find(columnNameInput).val());
      });
  }

  return {
    init: () => {
      initDropdownItemsTextArea();
    },
    checkValidation: () => {
      var $manageModal = $(manageModal);
      var count = $manageModal.find('.list-items-count').attr('data-count');
      return count < GLOBAL_CONSTANTS.REPOSITORY_LIST_ITEMS_PER_COLUMN;
    },
    loadParams: () => {
      var repositoryColumnParams = {};
      repositoryColumnParams.repository_list_items_attributes = JSON.parse($('#dropdown_options').val());
      repositoryColumnParams.delimiter = $('#delimiter').data('used-delimiter');
      return repositoryColumnParams;
    }
  };
}());
