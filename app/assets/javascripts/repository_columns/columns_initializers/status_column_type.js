/* global I18n */
/* eslint-disable no-unused-vars */
var RepositoryStatusColumnType = (function() {
  var manageModal = '#manageRepositoryColumn';

  function statusTemplate() {
    return `
    <div class="status-item-container loading">
      <div class="status-item-icon"></div>
        <input placeholder=${I18n.t('libraries.manange_modal_column.name_placeholder')}
               class="status-item-field"
               type="text"/>
        <span class="status-item-icon-trash fas fa-trash"></span>
      </div>
    </div>`;
  }

  function initActions() {
    var $manageModal = $(manageModal);
    var addStatusOptionBtn = '.add-status';
    var deleteStatusOptionBtn = '.status-item-icon-trash';

    $manageModal.off('click', addStatusOptionBtn).on('click', addStatusOptionBtn, function() {
      var newStatusRow = $(statusTemplate()).insertBefore($(this));
      setTimeout(function() {
        newStatusRow.css('height', '34px');
      }, 0);
      setTimeout(function() {
        newStatusRow.removeClass('loading');
        newStatusRow.find('input').focus();
      }, 300);
    });

    $manageModal.off('click', deleteStatusOptionBtn).on('click', deleteStatusOptionBtn, function() {
      var statusRow = $(this).parent();
      setTimeout(function() {
        statusRow.addClass('loading');
        statusRow.css('height', '0px');
      }, 0);
      setTimeout(function() {
        statusRow.remove();
      }, 300);
    });
  }

  return {
    init: () => {
      initActions();
    }
  };
}());
