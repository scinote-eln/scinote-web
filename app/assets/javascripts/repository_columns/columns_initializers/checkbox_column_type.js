/* global GLOBAL_CONSTANTS dropdownSelector RepositoryListColumnType */
 
var RepositoryCheckboxColumnType = (function() {
  var manageModal = '#manage-repository-column';
  var delimiterDropdown = '.checkbox-column-type .delimiter';
  var itemsTextarea = '.checkbox-column-type .items-textarea';
  var previewContainer = '.checkbox-column-type .dropdown-preview';
  var dropdownOptions = '.checkbox-column-type .dropdown-options';

  function initCheckboxDropdown() {
    dropdownSelector.init(previewContainer + ' .preview-select', {
      noEmptyOption: true,
      optionClass: 'checkbox-icon',
      selectAppearance: 'simple'
    });
  }

  function initDropdownItemsTextArea() {
    var $manageModal = $(manageModal);
    var columnNameInput = '#repository-column-name';


    $manageModal
      .on('show.bs.modal', function() {
        setTimeout(() => { initCheckboxDropdown(); }, 200);
      })
      .on('change keyup paste', itemsTextarea, function() {
        RepositoryListColumnType.refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions
        );
        initCheckboxDropdown();
      })
      .on('change', delimiterDropdown, function() {
        RepositoryListColumnType.refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions
        );
        initCheckboxDropdown();
      })
      .on('columnModal::partialLoadedForRepositoryCheckboxValue', function() {
        RepositoryListColumnType.refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions
        );
        initCheckboxDropdown();
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
      var count = $manageModal.find(previewContainer).find('.items-count').attr('data-count');
      return count < GLOBAL_CONSTANTS.REPOSITORY_LIST_ITEMS_PER_COLUMN;
    },
    loadParams: () => {
      var repositoryColumnParams = {};
      var options = JSON.parse($(dropdownOptions).val());
      repositoryColumnParams.repository_checkbox_items_attributes = options;
      repositoryColumnParams.delimiter = $(delimiterDropdown).data('used-delimiter');
      return repositoryColumnParams;
    }
  };
}());
