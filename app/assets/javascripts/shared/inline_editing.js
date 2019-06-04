/* eslint no-unused-vars: ["error", { "varsIgnorePattern": "initInlineEditing" }]*/
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

    function updateField() {
      var params = {};

      if (inputString.value === editBlock.dataset.originalName) {
        inputString.disabled = true;
        editBlock.dataset.editMode = 0;
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
