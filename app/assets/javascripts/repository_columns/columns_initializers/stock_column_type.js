/* global GLOBAL_CONSTANTS dropdownSelector RepositoryListColumnType */

var RepositoryStockColumnType = (function() {
  var manageModal = '#manage-repository-column';
  var delimiterDropdown = '.stock-column-type #delimiter';
  var itemsTextarea = '.stock-column-type .items-textarea';
  var previewContainer = '.stock-column-type .dropdown-preview';
  var dropdownOptions = '.stock-column-type #dropdown-options';

  function initStockUnitDropdown() {
    dropdownSelector.init(previewContainer + ' .preview-select', {
      noEmptyOption: true,
      singleSelect: true,
      selectAppearance: 'simple',
      closeOnSelect: true
    });
  }

  function syncSelectedUnits() {
    RepositoryListColumnType.refreshPreviewDropdownList(
      previewContainer,
      itemsTextarea,
      delimiterDropdown,
      dropdownOptions,
      GLOBAL_CONSTANTS.REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN
    );
  }

  function initDropdownItemsTextArea() {
    var $manageModal = $(manageModal);

    $manageModal
      .on('show.bs.modal', function() {
        setTimeout(() => { initStockUnitDropdown(); }, 200);
      })
      .on('change keyup paste', itemsTextarea, function() {
        syncSelectedUnits();
        $('.changing-existing-stock-units-warning').removeClass('hidden');
        initStockUnitDropdown();
      })
      .on('columnModal::partialLoadedForRepositoryStockValue', function() {
        syncSelectedUnits();
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
      if ($manageModal.find('.stock-column-type .items-textarea').val().length) {
        $manageModal.find('.stock-column-type .items-textarea').parent().removeClass('error');
      } else {
        $manageModal.find('.stock-column-type .items-textarea').parent().addClass('error');
        return false;
      }
      return count <= GLOBAL_CONSTANTS.REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN;
    },
    loadParams: () => {
      let repositoryColumnParams = {};
      syncSelectedUnits();
      let options = JSON.parse($(dropdownOptions).val());
      let decimals = $('.stock-column-type #decimals').val();
      repositoryColumnParams.repository_stock_unit_items_attributes = options;
      repositoryColumnParams.metadata = { decimals: decimals };
      return repositoryColumnParams;
    },
    initStockUnitDropdown: () => {
      initStockUnitDropdown();
    }
  };
}());
