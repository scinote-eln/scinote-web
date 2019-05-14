/* eslint no-unused-vars: ["error", { "varsIgnorePattern": "initInlineEditing" }]*/
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
      $inputString.off('keydown').on('keydown', function() {
        var el = this;
        setTimeout(() => {
          el.style.cssText = 'height:0px; padding:0';
          el.style.cssText = 'height:' + (el.scrollHeight + 10) + 'px';
        }, 0);
      });
      $inputString.keydown();
    }
    inputString = $inputString[0];

    function saveAllEditFields() {
      $('.inline-edit-active').find('.save-button').click();
    }

    function updateField() {
      var params = {};

      if (inputString.value === editBlock.dataset.originalName) {
        inputString.disabled = true;
        editBlock.dataset.editMode = 0;
        return false;
      }
      params[editBlock.dataset.paramsGroup] = {};
      params[editBlock.dataset.paramsGroup][editBlock.dataset.fieldToUpdate] = inputString.value;
      $.ajax({
        url: editBlock.dataset.pathToUpdate,
        type: 'PUT',
        dataType: 'json',
        data: params,
        success: function() {
          editBlock.dataset.originalName = inputString.value;
          editBlock.dataset.error = false;
          inputString.disabled = true;
          editBlock.dataset.editMode = 0;
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
        }
      });
      return true;
    }

    $editBlock.click(e => {
      if (inputString.disabled) {
        saveAllEditFields();
        editBlock.dataset.editMode = 1;
        inputString.disabled = false;
        $inputString.focus();
      }
      e.stopPropagation();
    });

    $(window).click(() => {
      if (inputString.disabled === false) {
        updateField();
      }
      editBlock.dataset.editMode = 0;
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
      $inputString.keydown();
      e.stopPropagation();
    });

    return true;
  });
}
