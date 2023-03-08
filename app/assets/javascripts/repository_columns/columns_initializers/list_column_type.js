/* global GLOBAL_CONSTANTS dropdownSelector I18n */
/* eslint-disable no-unused-vars */
var RepositoryListColumnType = (function() {
  var manageModal = '#manage-repository-column';
  var delimiterDropdown = '.list-column-type #delimiter';
  var itemsTextarea = '.list-column-type #items-textarea';
  var previewContainer = '.list-column-type  .dropdown-preview';
  var dropdownOptions = '.list-column-type #dropdown-options';

  function initListDropdown() {
    dropdownSelector.init(previewContainer + ' .preview-select', {
      noEmptyOption: true,
      singleSelect: true,
      selectAppearance: 'simple',
      closeOnSelect: true
    });
  }

  function initUpdatePlaceholder(delimiter) {
    var value = delimiter.value;
    var placeholder = I18n.t('libraries.manange_modal_column.list_type.items_placeholders.' + value);
    $(itemsTextarea).attr('placeholder', placeholder);
  }

  function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
  }

  function textToItems(text, delimiterContainer) {
    var delimiter = $(delimiterContainer).val();
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

    $(delimiterContainer).attr('data-used-delimiter', usedDelimiter);
    return res;
  }

  function pluralizeWord(count, noun, suffix = 's') {
    return `${noun}${count !== 1 ? suffix : ''}`;
  }


  function drawDropdownPreview(items, container) {
    var $manageModal = $(manageModal);
    var $dropdownPreview = $manageModal.find(container).find('.preview-select');
    $('option', $dropdownPreview).remove();
    $.each(items, function(i, item) {
      $dropdownPreview.append($('<option>', {
        value: item,
        text: item
      }));
    });
  }

  function refreshCounter(number, limit) {
    var $manageModal = $(manageModal);
    var $counterContainer = $manageModal.find('.limit-counter-container');
    var $btn = $manageModal.find('.column-save-btn');
    var $textarea = $counterContainer.parents('.form-group').find('textarea');

    $counterContainer.find('.items-count').text(number).attr('data-count', number);

    if (number > limit) {
      $counterContainer.addClass('error-to-many-items');
      $textarea.addClass('too-many-items');
      $btn.addClass('disabled');
    } else {
      $counterContainer.removeClass('error-to-many-items');
      $textarea.removeClass('too-many-items');
      $btn.removeClass('disabled');
    }
  }

  function refreshPreviewDropdownList(preview, textarea, delimiterContainer, dropdown, limit) {
    var items = textToItems($(textarea).val(), delimiterContainer);
    var hashItems = [];
    drawDropdownPreview(items, preview);
    refreshCounter(items.length, limit);

    $.each(items, (index, option) => {
      hashItems.push({ data: option });
    });

    $(dropdown).val(JSON.stringify(hashItems));
    $(preview).find('.items-label').html(pluralizeWord(items.length, 'item'));
  }

  function initDropdownItemsTextArea() {
    var $manageModal = $(manageModal);
    var columnNameInput = '#repository-column-name';

    $manageModal
      .on('change keyup paste', itemsTextarea, function() {
        refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions,
          GLOBAL_CONSTANTS.REPOSITORY_LIST_ITEMS_PER_COLUMN
        );
        initListDropdown();
        $('.changing-existing-list-items-warning').removeClass('hidden');
      })
      .on('change', delimiterDropdown, function() {
        initUpdatePlaceholder(this);
        refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions,
          GLOBAL_CONSTANTS.REPOSITORY_LIST_ITEMS_PER_COLUMN
        );
        initListDropdown();
      })
      .on('columnModal::partialLoadedForRepositoryListValue', function() {
        refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions,
          GLOBAL_CONSTANTS.REPOSITORY_LIST_ITEMS_PER_COLUMN
        );
        initListDropdown();
      })
      .on('keyup change', columnNameInput, function() {
        $manageModal.find(previewContainer).find('.preview-label').html($manageModal.find(columnNameInput).val());
      });
  }

  return {
    init: () => {
      initDropdownItemsTextArea();
    },
    checkValidation: () => {
      var $manageModal = $(manageModal);
      var count = $manageModal.find('.items-count').attr('data-count');
      return count <= GLOBAL_CONSTANTS.REPOSITORY_LIST_ITEMS_PER_COLUMN;
    },
    loadParams: () => {
      var repositoryColumnParams = {};
      var options = JSON.parse($(dropdownOptions).val());
      repositoryColumnParams.repository_list_items_attributes = options;
      repositoryColumnParams.metadata = { delimiter: $(delimiterDropdown).data('used-delimiter') };
      return repositoryColumnParams;
    },

    refreshPreviewDropdownList: (preview, textarea, delimiter, dropdown, limit) => {
      refreshPreviewDropdownList(preview, textarea, delimiter, dropdown, limit);
    },

    initListDropdown: () => {
      initListDropdown();
    },

    initListPlaceholder: () => {
      initUpdatePlaceholder($(delimiterDropdown)[0]);
    }
  };
}());
