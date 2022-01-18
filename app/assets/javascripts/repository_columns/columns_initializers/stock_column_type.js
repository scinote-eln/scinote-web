/* global GLOBAL_CONSTANTS dropdownSelector RepositoryListColumnType */

var RepositoryStockColumnType = (function() {
  var manageModal = '#manage-repository-column';
  var delimiterDropdown = '.stock-column-type #delimiter';
  var itemsTextarea = '.stock-column-type .items-textarea';
  var previewContainer = '.stock-column-type .dropdown-preview';
  var dropdownOptions = '.stock-column-type .dropdown-options';

  function initStockUnitDropdown() {
    dropdownSelector.init(previewContainer + ' .preview-select', {
      noEmptyOption: true,
      optionClass: 'checkbox-icon',
      selectAppearance: 'simple'
    });
  }

  function initDropdownItemsTextArea() {
    var $manageModal = $(manageModal);

    $manageModal
      .on('show.bs.modal', function() {
        setTimeout(() => { initStockUnitDropdown(); }, 200);
      })
      .on('change keyup paste', itemsTextarea, function() {
        RepositoryListColumnType.refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions,
          GLOBAL_CONSTANTS.REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN
        );
        $('.changing-existing-list-items-warning').removeClass('hidden');
        initStockUnitDropdown();
      })
      .on('columnModal::partialLoadedForRepositoryStockValue', function() {
        RepositoryListColumnType.refreshPreviewDropdownList(
          previewContainer,
          itemsTextarea,
          delimiterDropdown,
          dropdownOptions,
          GLOBAL_CONSTANTS.REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN
        );
        initStockUnitDropdown();
      });
  }

  return {
    init: () => {
      initDropdownItemsTextArea();
    },
    checkValidation: () => {
      var $manageModal = $(manageModal);
      var count = $manageModal.find('.items-count').attr('data-count');
      return count <= GLOBAL_CONSTANTS.REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN;
    },
    loadParams: () => {
      var repositoryColumnParams = {};
      var options = JSON.parse($(dropdownOptions).val());
      repositoryColumnParams.repository_stock_unit_items_attributes = options;
      repositoryColumnParams.metadata = { delimiter: '\\n' };
      return repositoryColumnParams;
    },
    initStockUnitDropdown: () => {
      initStockUnitDropdown();
    }
  };
}());
