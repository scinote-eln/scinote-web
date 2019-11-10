/* global GLOBAL_CONSTANTS I18n */
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

    $.each($statusRows, (index, statusRow) => {
      var $row = $(statusRow);
      var $statusField = $row.find('input.status-item-field');
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
      $manageModal.find('button[data-action="save"]').addClass('disabled');
    } else {
      $manageModal.find('button[data-action="save"]').removeClass('disabled');
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

    $manageModal.off('click', addStatusOptionBtn).on('click', addStatusOptionBtn, function() {
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

    $manageModal.off('click', deleteStatusOptionBtn).on('click', deleteStatusOptionBtn, function() {
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

    $manageModal.off('click', icon).on('click', icon, function() {
      var $emojiPicker = $(this).parent().next('.emojis-picker');
      $emojiPicker.show();
    });

    $manageModal.off('click', emojis).on('click', emojis, function() {
      var $clickedEmoji = $(this);
      var $iconField = $clickedEmoji.parent().prev().find('.status-item-icon');
      $clickedEmoji.parent().hide();
      $iconField.html($clickedEmoji.data('emoji-code'));
      $iconField.attr('data-icon', $clickedEmoji.data('emoji-code'));
      $iconField.trigger('data-attribute-changed', $iconField);
    });

    $manageModal.off('keyup change', statusInput).on('keyup change', statusInput, function() {
      validateForm();
    });

    $manageModal.off('data-attribute-changed').on('data-attribute-changed', function() {
      validateForm();
    });

    $manageModal.off('columnModal::partialLoadedForStatuses').on('columnModal::partialLoadedForStatuses', function() {
      validateForm();
    });

    $manageModal.off('click', buttonWrapper).on('click', buttonWrapper, function() {
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
    }
  };
}());
