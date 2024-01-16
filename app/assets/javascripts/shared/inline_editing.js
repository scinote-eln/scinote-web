/* eslint no-unused-vars: ["error", { "varsIgnorePattern": "initInlineEditing" }]*/
/* global SmartAnnotation HelperModule I18n */

let inlineEditing = (function() {
  const SIDEBAR_ITEM_TYPES = ['project', 'experiment', 'my_module', 'repository'];

  const editBlocks = '.inline-init-handler';

  function appendAfterLabel(container) {
    if (container.data('label-after')) {
      $(container.data('label-after')).appendTo(container.find('.view-mode'));
    }

    if ($(container).data('params-group') === 'protocol' && $(container).hasClass('inline-editing-container')) {
      $('.view-mode').text(I18n.t('protocols.draft_name', { name: $('.view-mode').text() }));
    }
  }

  function inputField(container) {
    return container.find('input, textarea');
  }

  function initSmartAnnotation(container) {
    if (container.data('smart-annotation')) {
      SmartAnnotation.init(inputField(container), false);
    }
  }

  function initFields() {
    $(editBlocks).not('.initialized').each(function() {
      var container = $(this);
      container.addClass('initialized');
      initSmartAnnotation(container);
      appendAfterLabel(container);
    });
  }

  function updateSideBarNav(itemType, itemId, newData) {
    let sidebar = $('#slide-panel');
    let link = sidebar.find(`a[data-type="${itemType}"][data-id="${itemId}"]`);
    link.prop('title', newData);
    link.text(newData);
  }

  function updateField(container) {
    var params;
    var paramsGroup = container.data('params-group');
    var itemId = container.data('item-id');
    var fieldToUpdate = container.data('field-to-update');

    if (inputField(container).val() === container.attr('data-original-name')) {
      $(`${editBlocks} .cancel-button`).trigger('click');
      return false;
    }
    if (container.data('disabled')) return false;
    container.data('disabled', true);

    if (paramsGroup) {
      params = { [paramsGroup]: { [fieldToUpdate]: inputField(container).val() } };
    } else {
      params = { [fieldToUpdate]: inputField(container).val() };
    }

    $.ajax({
      url: container.data('path-to-update'),
      type: 'PUT',
      dataType: 'json',
      data: params,
      success: function(result) {
        var viewData;
        var parentContainer = container.parent();
        if (container.data('response-field')) {
          // If we want to modify preview element on backend
          // we can use this data field and we will take string from response
          viewData = result[container.data('response-field')];
        } else {
          // By default we just copy value from input string
          viewData = $('<div>').text(inputField(container).val()).html();
        }

        container.find('.view-mode')
          .html(viewData)
          .removeClass('hidden');
        container
          .attr('data-original-name', inputField(container).val())
          .removeClass('error')
          .attr('data-edit-mode', '0')
          .data('disabled', false)
          .trigger('inlineEditing:fieldUpdated');
        inputField(container)
          .attr('disabled', true)
          .addClass('hidden')
          .attr('value', inputField(container).val());
        appendAfterLabel(container);

        container.trigger('inlineEditing::updated', [inputField(container).val(), viewData]);

        if (SIDEBAR_ITEM_TYPES.includes(paramsGroup)) {
          updateSideBarNav(paramsGroup, itemId, viewData);
        }

        if (parentContainer.attr('data-original-title')) {
          parentContainer.attr('data-original-title', inputField(container).val());
        }
      },
      error: function(response) {
        var error = response.responseJSON[fieldToUpdate];
        if (response.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
        } else if (response.status === 422) {
          HelperModule.flashAlertMsg(response.responseJSON.errors
            ? Object.values(response.responseJSON.errors).join(', ') : I18n.t('errors.general'), 'danger');
        }
        if (!error) error = response.responseJSON.errors[fieldToUpdate];
        container.addClass('error');
        if (error) container.find('.error-block').html(error.join(', '));
        inputField(container).removeClass('!border-b-sn-science-blue');
        inputField(container).addClass('!border-b-sn-delete-red');
        inputField(container).focus();
        container.data('disabled', false);
        $('.tooltip').hide();
      }
    });
    return true;
  }

  function saveAllEditFields() {
    $(editBlocks).each(function() {
      var container = $(this);
      if (!inputField(container).attr('disabled')) {
        updateField(container);
      }
    });
  }

  $(document)
    .off('click', editBlocks)
    .off('keyup', `${editBlocks}`)
    .off('click', `${editBlocks} .save-button`)
    .off('click', `${editBlocks} .cancel-button`)
    .off('blur', `${editBlocks} textarea, ${editBlocks} input`)
    .on('keyup', `${editBlocks}`, function(e) {
      var container = $(this);
      if (e.keyCode === 27) {
        $(`${editBlocks} .cancel-button`).click();
      } // Esc
      if (e.keyCode === 13 && !container.find('.view-mode').hasClass('hidden')) {
        $(editBlocks).click();
      }
    })
    .on('click', editBlocks, function(e) {
    // 'A' mean that, if we click on <a></a> element we will not go in edit mode
      var container = $(this);
      if (e.target.tagName === 'A') return true;
      if (inputField(container).attr('disabled')) {
        saveAllEditFields();
        let input = inputField(container);
        input.attr('disabled', false)
          .removeClass('hidden')
          .focus();
        input[0].selectionStart = input[0].value.length;
        input[0].selectionEnd = input[0].value.length;
        container
          .attr('data-edit-mode', '1');
        container.find('.view-mode')
          .addClass('hidden')
          .closest('.inline_scroll_block')
          .scrollTop(container.offsetTop);
        $('.tooltip').hide();
      }
      inputField(container).removeClass('!border-b-sn-delete-red');
      inputField(container).addClass('!border-b-sn-science-blue');
      e.stopPropagation();
      return true;
    })
    .on('click', `${editBlocks} .save-button`, function(e) {
      var container = $(this).closest(editBlocks);
      updateField(container);
      e.stopPropagation();
    })
    .on('click', `${editBlocks} .cancel-button`, function(e) {
      var container = $(this).closest(editBlocks);
      inputField(container)
        .attr('disabled', true)
        .addClass('hidden')
        .val(container.data('original-name'));
      container
        .attr('data-edit-mode', '0')
        .removeClass('error');
      container.find('.view-mode')
        .removeClass('hidden');
      e.stopPropagation();
    })
    .on('keydown', `${editBlocks} input`, function(e) {
      var container = $(this).closest(editBlocks);
      if (e.keyCode === 13) {
        updateField(container);
      } else if (e.keyCode === 9) {
        $(`${editBlocks} .cancel-button`).trigger('click');
      }
      e.stopPropagation();
    });

  $(window).click((e) => {
    if ($(e.target).closest('.atwho-view').length > 0) return false;
    saveAllEditFields();
    return true;
  });

  return {
    init: () => {
      initFields();
    }
  };
}());

$(document).on('turbolinks:load', function() {
  inlineEditing.init();
});
