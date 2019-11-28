/* global GLOBAL_CONSTANTS I18n */
/* eslint-disable no-unused-vars */
var RepositoryStatusColumnType = (function() {
  var manageModal = '#manage-repository-column';

  function statusTemplate() {
    return `
    <div class="status-item-container loading">
      <div class="status-item-icon"></div>
      <input placeholder=${I18n.t('libraries.manange_modal_column.name_placeholder')}
             class="status-item-field"
             type="text"/>
      <span class="status-item-icon-trash fas fa-trash"></span>
    </div>
    <div class="emojis-picker">
      <span data-emoji-code="&#128540;">&#128540;</span>
      <span data-emoji-code="&#128520;">&#128520;</span>
      <span data-emoji-code="&#128526;">&#128526;</span>
      <span data-emoji-code="&#128531;">&#128531;</span>
      <span data-emoji-code="&#128535;">&#128535;</span>
      <span data-emoji-code="&#128536;">&#128536;</span>
    </div>`;
  }

  function validateForm() {
    var $manageModal = $(manageModal);
    var $statusRows = $manageModal.find('.status-item-container:not([data-removed])');
    var $btn = $manageModal.find('.column-save-btn');

    $.each($statusRows, (index, statusRow) => {
      var $row = $(statusRow);
      var $statusField = $row.find('.status-item-field');
      var $icon = $row.find('.status-item-icon');
      var stringLength = $statusField.val().length;

      if (stringLength < GLOBAL_CONSTANTS.NAME_MIN_LENGTH
          || stringLength > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
          || !$icon.attr('data-icon')) {
        $row.addClass('error');
      } else {
        $row.removeClass('error');
      }
    });

    if ($manageModal.find('.error').length > 0) {
      $btn.addClass('disabled');
    } else {
      $btn.removeClass('disabled');
    }
  }

  function highlightErrors() {
    $(manageModal).find('.error').addClass('error-highlight');
  }

  function initActions() {
    var $manageModal = $(manageModal);
    var addStatusOptionBtn = '.add-status';
    var deleteStatusOptionBtn = '.status-item-icon-trash';
    var icon = '.status-item-icon';
    var emojis = '.emojis-picker>span';
    var statusInput = 'input.status-item-field';
    var buttonWrapper = '.button-wrapper';

    $manageModal.on('click', addStatusOptionBtn, function() {
      var newStatusRow = $(statusTemplate()).insertBefore($(this));
      validateForm();
      setTimeout(function() {
        newStatusRow.css('height', '34px');
      }, 0);
      setTimeout(function() {
        newStatusRow.removeClass('loading');
        newStatusRow.find('input').focus();
      }, 300);
    });

    $manageModal.on('click', deleteStatusOptionBtn, function() {
      // if existing item is deleted, flag it as deleted
      // if new item is deleted, remove it from HTML

      var $statusRow = $(this).parent();
      var $emojis = $statusRow.next('.emojis-picker');
      var isNewRow = $statusRow.data('id') == null;

      setTimeout(function() {
        $statusRow.addClass('loading');
        $statusRow.css('height', '0px');
      }, 0);
      setTimeout(function() {
        if (isNewRow) {
          $statusRow.remove();
          validateForm();
        } else {
          $statusRow.attr('data-removed', 'true');
          $statusRow.removeClass('loading');
          $statusRow.removeClass('error');
          validateForm();
        }
        $emojis.remove();
      }, 300);
    });

    $manageModal.on('click', icon, function() {
      var $emojiPicker = $(this).parent().next('.emojis-picker');
      $emojiPicker.show();
    });

    $manageModal.on('click', emojis, function() {
      var $clickedEmoji = $(this);
      var $iconField = $clickedEmoji.parent().prev().find('.status-item-icon');
      $clickedEmoji.parent().hide();
      $iconField.html($clickedEmoji.data('emoji-code'));
      $iconField.attr('data-icon', $clickedEmoji.data('emoji-code'));
      $iconField.trigger('data-attribute-changed', $iconField);
    });

    $manageModal
      .on('keyup change', statusInput, function() {
        validateForm();
      })
      .on('data-attribute-changed columnModal::partialLoadedForRepositoryStatusValue', function() {
        validateForm();
      })
      .on('click', buttonWrapper, function() {
        highlightErrors();
      });
  }

  return {
    init: () => {
      initActions();
    },
    checkValidation: () => {
      highlightErrors();
      return !($(manageModal).find('.error').length > 0);
    },
    loadParams: () => {
      var $modal = $(manageModal);
      var $statusItems;
      var repositoryColumnParams = {};

      $statusItems = $modal.find('.status-item-container');
      // Load all new items
      // Load all existing items, delete flag included
      repositoryColumnParams.repository_status_items_attributes = [];

      $.each($statusItems, function(index, value) {
        var $item = $(value);
        var id = $item.data('id');
        var removed = $item.data('removed');
        var icon = $item.find('.status-item-icon').data('icon');
        var status = $item.find('input.status-item-field').val();

        if (removed && id) { // flag as item for removing
          repositoryColumnParams.repository_status_items_attributes
            .push({ id: id, _destroy: true });
        } else if (id) { // existing element, maybe values needs to be updated
          repositoryColumnParams.repository_status_items_attributes
            .push({ id: id, icon: icon, status: status });
        } else { // new element
          repositoryColumnParams.repository_status_items_attributes
            .push({ icon: icon, status: status });
        }
      });

      return repositoryColumnParams;
    }
  };
}());
