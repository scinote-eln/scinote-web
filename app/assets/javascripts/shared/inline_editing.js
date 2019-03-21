function initInlineEditing(title) {
  var editBlock = $('.' + title + '-editable-field');
  var inputString = editBlock.find('input');

  function updateField() {
    var params = {};

    if (inputString[0].value === editBlock[0].dataset.originalName) {
      inputString[0].disabled = true;
      return false;
    }
    params[editBlock[0].dataset.paramsGroup] = {};
    params[editBlock[0].dataset.paramsGroup][editBlock[0].dataset.fieldToUpdate] = inputString[0].value;
    $.ajax({
      url: editBlock[0].dataset.pathToUpdate,
      type: 'PUT',
      dataType: 'json',
      data: params,
      success: function() {
        editBlock[0].dataset.originalName = inputString[0].value;
        editBlock[0].dataset.error = false;
        inputString[0].disabled = true;
      },
      error: function(response) {
        var errors = response.responseJSON;
        editBlock[0].dataset.error = true;
        if (response.responseJSON.errors === undefined) {
          errors = errors[editBlock[0].dataset.fieldToUpdate][0];
        } else {
          errors = errors.errors[editBlock[0].dataset.fieldToUpdate][0];
        }
        editBlock.find('.error-block')[0].innerHTML = errors;
        inputString.focus();
      }
    });
  }

  editBlock.click(e => {
    if (inputString[0].disabled) {
      inputString[0].disabled = false;
      inputString.focus();
    }
    e.stopPropagation();
  });

  $(window).click(() => {
    if (inputString[0].disabled === false) {
      updateField();
    }
  });

  $(editBlock.find('.save-button')).click(e => {
    updateField();
    e.stopPropagation();
  });

  $(editBlock.find('.cancel-button')).click(e => {
    inputString[0].disabled = true;
    editBlock[0].dataset.error = false;
    inputString[0].value = editBlock[0].dataset.originalName;
    e.stopPropagation();
  });
}
