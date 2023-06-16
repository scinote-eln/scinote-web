/* global GLOBAL_CONSTANTS I18n EmojiButton twemoji */
/* eslint-disable no-unused-vars, no-use-before-define, consistent-return, no-param-reassign */

var RepositoryStatusColumnType = (function() {
  var manageModal = '#manage-repository-column';
  var iconId = '.status-item-icon';

  function statusTemplate() {
    return `
    <div class="status-item-container loading">
      <div class="status-item-icon"></div>
      <input placeholder=${I18n.t('libraries.manange_modal_column.name_placeholder')}
             class="status-item-field"
             type="text"/>
      <span class="status-item-icon-trash sn-icon sn-icon-delete"></span>
    </div>`;
  }

  function validateForm() {
    var $manageModal = $(manageModal);
    var $statusRows = $manageModal.find('.status-item-container:not([data-removed])');
    var $btn = $manageModal.find('.column-save-btn');

    $.each($statusRows, (index, statusRow) => {
      var $row = $(statusRow);
      var $statusField = $row.find('.status-item-field');
      var icon = $row.find(iconId).attr('emoji');
      var stringLength = $statusField.val().length;

      if (stringLength < GLOBAL_CONSTANTS.NAME_MIN_LENGTH
          || stringLength > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
          || !icon) {
        $row.addClass('error').attr('data-error-text', I18n.t('libraries.manange_modal_column.status_type.errors.icon_and_name_error'));
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

  function initEmojiPicker() {
    // init Emoji picker modal
    $(manageModal)
      .on('click', iconId, function() {
        var picker = new EmojiButton({ rootElement: document.getElementById('manage-repository-column') });
        var iconElement = this;
        picker.on('emoji', emoji => {
          $(iconElement).attr('emoji', emoji.emoji).html(twemoji.parse(emoji.emoji));
          validateForm();
        });

        if (picker.pickerVisible) {
          picker.hidePicker();
        } else {
          picker.showPicker(iconElement);
        }
        $.each($('.emoji-picker__emojis').last().find('.emoji-picker__container'), function(i, container) {
          twemoji.parse(container);
        });
      })
      .on('click', '.emoji-picker__tab-body.active .emoji-picker__emoji', function() {
        if ($('.emoji-picker__variant-popup').length) {
          twemoji.parse($('.emoji-picker__variant-popup')[0]);
        }
      })
      .on('click', '.emoji-picker__tab', function() {
        $.each($('.emoji-picker__tab'), (i, tab) => {
          if ($(tab).hasClass('active')) {
            twemoji.parse($('.emoji-picker__container')[i]);
          }
        });
      });
  }

  function initActions() {
    var $manageModal = $(manageModal);
    var addStatusOptionBtn = '.add-status';
    var deleteStatusOptionBtn = '.status-item-icon-trash';
    var statusInput = 'input.status-item-field';
    var buttonWrapper = '.button-wrapper';

    initEmojiPicker();
    $manageModal.on('click', addStatusOptionBtn, function() {
      var newStatusRow = $(statusTemplate()).insertBefore($(this));
      var newIcon = newStatusRow.find(iconId);
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
      }, 300);
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
        var icon = $item.find(iconId).attr('emoji');
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
    },

    updateLoadedEmojies: () => {
      $.each($('.status-column-type .status-item-icon'), (i, icon) => {
        $(icon).html(twemoji.parse(icon.innerHTML));
      });
    }
  };
}());
