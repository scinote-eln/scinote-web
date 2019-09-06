/* eslint no-unused-vars: ["error", { "varsIgnorePattern": "initInlineEditing" }]*/
<<<<<<< HEAD
/* global SmartAnnotation HelperModule I18n */

var inlineEditing = (function() {
  const SIDEBAR_ITEM_TYPES = ['project', 'experiment', 'my_module', 'repository'];

  var editBlocks = '.inline-init-handler';

  function appendAfterLabel(container) {
    if (container.data('label-after')) {
      $(container.data('label-after')).appendTo(container.find('.view-mode'));
    }
  }

  function inputField(container) {
    return container.find('input, textarea');
  }

  function initSmartAnnotation(container) {
    if (container.data('smart-annotation')) {
      SmartAnnotation.init(inputField(container));
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
      inputField(container)
        .attr('disabled', true)
        .addClass('hidden');
      container
        .removeClass('error')
        .attr('data-edit-mode', '0');
      container.find('.view-mode')
        .removeClass('hidden');
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

        container.trigger('inlineEditing::updated', [inputField(container).val(), viewData])

        if (SIDEBAR_ITEM_TYPES.includes(paramsGroup)) {
          updateSideBarNav(paramsGroup, itemId, viewData);
        }
      },
      error: function(response) {
        var error = response.responseJSON[fieldToUpdate];
        if (response.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
        }
        if (!error) error = response.responseJSON.errors[fieldToUpdate];
        container.addClass('error');
        container.find('.error-block').html(error.join(', '));
        inputField(container).focus();
        container.data('disabled', false);
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
    .off('click', `${editBlocks} .save-button`)
    .off('click', `${editBlocks} .cancel-button`)
    .off('blur', `${editBlocks} textarea, ${editBlocks} input`)
    .on('click', editBlocks, function(e) {
    // 'A' mean that, if we click on <a></a> element we will not go in edit mode
      var container = $(this);
      if (e.target.tagName === 'A') return true;
      if (inputField(container).attr('disabled')) {
        saveAllEditFields();

        inputField(container)
          .attr('disabled', false)
          .removeClass('hidden')
          .focus();
        container
          .attr('data-edit-mode', '1');
        container.find('.view-mode')
          .addClass('hidden')
          .closest('.inline_scroll_block')
          .scrollTop(container.offsetTop);
      }
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
    .on('keyup', `${editBlocks} input`, function(e) {
      var container = $(this).closest(editBlocks);
      if (e.keyCode === 13) {
        updateField(container);
      }
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
=======
/* global SmartAnnotation */
function initInlineEditing(title) {
  var editBlocks = $('.' + title + '-editable-field');

  $.each(editBlocks, function(i, element) {
    var editBlock = element;
    var $editBlock = $(editBlock);
    var $inputString = $editBlock.find('input');
    var inputString;
    if (editBlock.dataset.editMode !== undefined) return true;
    editBlock.dataset.editMode = 0;
    $editBlock.addClass('inline-edit-active');
    if ($inputString.length === 0) {
      $inputString = $editBlock.find('textarea');
    }

    inputString = $inputString[0];

    if (editBlock.dataset.smartAnnotation === 'true') {
      SmartAnnotation.init($inputString);
    }

    function saveAllEditFields() {
      $('.inline-edit-active').find('.save-button').click();
    }

    function appendAfterLabel() {
      if (editBlock.dataset.labelAfter) {
        $(editBlock.dataset.labelAfter).appendTo($editBlock.find('.view-mode'));
      }
    }
    appendAfterLabel();

    function updateField() {
      var params = {};

      if (inputString.value === editBlock.dataset.originalName) {
        inputString.disabled = true;
        editBlock.dataset.editMode = 0;
        editBlock.dataset.error = false;
        $inputString.addClass('hidden');
        $editBlock.find('.view-mode').removeClass('hidden');
        return false;
      }
      if (editBlock.disable) return false;
      editBlock.disable = true;
      params[editBlock.dataset.paramsGroup] = {};
      params[editBlock.dataset.paramsGroup][editBlock.dataset.fieldToUpdate] = inputString.value;
      $.ajax({
        url: editBlock.dataset.pathToUpdate,
        type: 'PUT',
        dataType: 'json',
        data: params,
        success: function(result) {
          var viewData;
          if (editBlock.dataset.responseField) {
            // If we want to modify preview element on backend
            // we can use this data field and we will take string from response
            viewData = result[editBlock.dataset.responseField];
          } else {
            // By default we just copy value from input string
            viewData = inputString.value;
          }
          editBlock.dataset.originalName = inputString.value;
          editBlock.dataset.error = false;
          $inputString.addClass('hidden');
          $editBlock.find('.view-mode').html(viewData).removeClass('hidden');
          appendAfterLabel();

          inputString.disabled = true;
          editBlock.dataset.editMode = 0;
          editBlock.disable = false;
        },
        error: function(response) {
          var errors = response.responseJSON;
          editBlock.dataset.error = true;
          if (response.responseJSON.errors === undefined) {
            errors = errors[editBlock.dataset.fieldToUpdate][0];
          } else {
            errors = errors.errors[editBlock.dataset.fieldToUpdate][0];
          }
          $editBlock.find('.error-block')[0].innerHTML = errors;
          $inputString.focus();
          editBlock.disable = false;
        }
      });
      return true;
    }

    $editBlock.click((e) => {
      // 'A' mean that, if we click on <a></a> element we will not go in edit mode
      if (e.target.tagName === 'A') return true;
      if (inputString.disabled) {
        saveAllEditFields();
        editBlock.dataset.editMode = 1;
        $editBlock.closest('.inline_scroll_block').scrollTop(editBlock.offsetTop);
        inputString.disabled = false;
        $inputString.removeClass('hidden');
        $editBlock.find('.view-mode').addClass('hidden');
        $inputString.focus();
      }
      e.stopPropagation();
      return true;
    });

    $(window).click((e) => {
      if ($(e.target).closest('.atwho-view').length > 0) return false;
      if (inputString.disabled === false) {
        updateField();
      }
      editBlock.dataset.editMode = 0;
      return true;
    });

    $($editBlock.find('.save-button')).click(e => {
      updateField();
      e.stopPropagation();
    });

    $inputString.keyup((e) => {
      if(e.keyCode === 13 && $inputString.is('input')) {
        updateField();
      }
    })

    $($editBlock.find('.cancel-button')).click(e => {
      inputString.disabled = true;
      editBlock.dataset.editMode = 0;
      editBlock.dataset.error = false;
      inputString.value = editBlock.dataset.originalName;
      $inputString.addClass('hidden');
      $editBlock.find('.view-mode').removeClass('hidden');
      $inputString.keydown();
      e.stopPropagation();
    });

    return true;
  });
}
>>>>>>> Finished merging. Test on dev machine (iMac).
