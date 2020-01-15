/* global GLOBAL_CONSTANTS dropdownSelector RepositoryListColumnType */

var RepositoryChecklistColumnType = (function() {
  var manageModal = '#manage-repository-column';
  var delimiterDropdown = '.checklist-column-type .delimiter';
  var itemsTextarea = '.checklist-column-type .items-textarea';
  var previewContainer = '.checklist-column-type .dropdown-preview';
  var dropdownOptions = '.checklist-column-type .dropdown-options';

  function initChecklistDropdown() {
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
        setTimeout(() => { initChecklistDropdown(); }, 200);
      })
      .on('change keyup paste', itemsTextarea, function() {
        RepositoryListColumnType.refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions
        );
        $('.changing-existing-list-items-warning').removeClass('hidden');
        initChecklistDropdown();
      })
      .on('change', delimiterDropdown, function() {
        RepositoryListColumnType.refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions
        );
        initChecklistDropdown();
      })
      .on('columnModal::partialLoadedForRepositoryChecklistValue', function() {
        RepositoryListColumnType.refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions
        );
        initChecklistDropdown();
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
      return count < GLOBAL_CONSTANTS.REPOSITORY_CHECKLIST_ITEMS_PER_COLUMN;
    },
    loadParams: () => {
      var repositoryColumnParams = {};
      var options = JSON.parse($(dropdownOptions).val());
      repositoryColumnParams.repository_checklist_items_attributes = options;
      repositoryColumnParams.metadata = { delimiter: $(delimiterDropdown).data('used-delimiter') };
      return repositoryColumnParams;
    }
  };
}());
