/*
 * Form validators. They'll find, render and focus error/s and
 * prevent form submission.
 */

/*
 * Calls specified validator along with the arguments on form submition.
 */
$.fn.onSubmitValidator = function(validatorCb) {
  var params = Array.prototype.slice.call(arguments, 1);
  var $form = $(this);
  if ($form.length) {
    $form.submit(function (ev) {
      $form.clearFormErrors();
      params.unshift(ev);
      validatorCb.apply(this, params);
    });
  }
};

/*
 * @param {boolean} clearErr Set clearErr to true if this is the only
 * error that can happen/show.
 */
function textValidator(ev, textInput, textLimitMin, textLimitMax, clearErr, tinyMCEInput) {
  clearErr = _.isUndefined(clearErr) ? false : clearErr;

  if(tinyMCEInput){
    var text = tinyMCEInput;
  } else {
    var text = $(textInput).val().trim();
    $(textInput).val(text);
    var text_from_html = $("<div/>").html(text).text();
    if (text_from_html.length < text.length) text = text_from_html;
  }

  var nameTooShort = text.length < textLimitMin;
  var nameTooLong = text.length > textLimitMax;

  var errMsg;
  if (nameTooShort) {
    if (textLimitMin === 1) {
      errMsg = I18n.t("general.text.not_blank");
    } else {
      errMsg = I18n.t("general.text.length_too_short", { min_length: textLimitMin });
    }
  } else if (nameTooLong) {
    errMsg = I18n.t("general.text.length_too_long", { max_length: textLimitMax });
  }

  var noErrors = _.isUndefined(errMsg);
  if (!noErrors) {
    renderFormError(ev, textInput, errMsg, clearErr);
  }
  return noErrors;
}

function checklistsValidator(ev, checklists, editMode) {
  var noErrors = true;
  // For every visible (i.e. not removed) checklist
  $(checklists).each(function() {
    var $checklist = $(this);
    if ($checklist.css('display') != 'none') {

      // For every visible (i.e. not removed) ckecklist item
      anyChecklistItemFilled = false;
      $(" .checklist-item-text", $checklist).each(function() {
        var $itemInput = $(this);
        var $item = $itemInput.closest("fieldset");
        if ($item.css('display') != 'none') {

          if ($itemInput.val()) {
            var itemNameValid = textValidator(ev, $itemInput, 1,
              $('#const_data').attr('data-TEXT_MAX_LENGTH'));
            if (!itemNameValid) {
              noErrors = false;
            }
            anyChecklistItemFilled = true;
          } else {
            // Remove empty checklist item input
            $item.remove();
          }
        }
      })

      var $checklistInput = $checklist.find(".checklist_name");
      // In edit mode, checklist's name can't be blank if any items present
      var allowBlankChklstName = !(anyChecklistItemFilled || editMode);
      var textLimitMin = allowBlankChklstName ? 0 : 1;
      var checklistNameValid = textValidator(ev, $checklistInput,
        textLimitMin, $('#const_data').attr('data-TEXT_MAX_LENGTH'));
      if (!checklistNameValid) {
        noErrors = false;
      } else if (allowBlankChklstName) {
        // Hide empty checklist (remove would break server-side logic)
        $checklist.hide();
      }
    }
  });

  return noErrors;
}

var FileTypeEnum = Object.freeze({
  FILE: $(document.body).data('file-max-size-mb') * 1024 * 1024,
  AVATAR: $(document.body).data('avatar-max-size-mb')
});
function filesValidator(ev, fileInputs, fileTypeEnum, canBeEmpty) {
  canBeEmpty = (typeof canBeEmpty !== 'undefined') ? canBeEmpty : false;
  var filesValid = true;
  if (fileInputs.length) {
    var filesPresentValid = canBeEmpty || filesPresentValidator(ev, fileInputs);
    var filesSizeValid = filesSizeValidator(ev, fileInputs, fileTypeEnum);

    // File spoof check is done on server-side only
    filesValid = filesPresentValid && filesSizeValid;
  }
  return filesValid;
}

function filesPresentValidator(ev, fileInputs) {
  var filesPresentValid = true;
  _.each(fileInputs, function(fileInput) {
    if (!fileInput.files[0]) {
      assetError = I18n.t("general.file.blank");
      renderFormError(ev, fileInput, assetError, false, "data-error='file-missing'");
      filesPresentValid = false;
    }
  });
  return filesPresentValid;
}

function filesSizeValidator(ev, fileInputs, fileTypeEnum) {

  function getFileTooBigError(file) {
    if (!file) {
      return ;
    }
    if (file.size > fileTypeEnum) {
      switch (fileTypeEnum) {
        case FileTypeEnum.FILE:
         return I18n.t('general.file.size_exceeded', { file_size: $(document.body).data('file-max-size-mb') }).strToErrorFormat();
        case FileTypeEnum.AVATAR:
          return $('#locale_data').attr('data-GENERAL_FILE_SIZE_EXCEEDED_AVATAR').strToErrorFormat();
      }
    }
  };

  function checkFilesTotalSize(fileInputs) {
    if (!fileInputs || fileInputs < 2) {
      return ;
    }

    var size = 0;
    _.each(fileInputs, function(fileInput) {
      var file = fileInput.files[0]
      size += file.size;
    })

    if (size > fileTypeEnum) {
      switch (fileTypeEnum) {
        case FileTypeEnum.FILE:
          return I18n.t('general.file.total_size', { size: $(document.body).data('file-max-size-mb') }).strToErrorFormat();
        case FileTypeEnum.AVATAR:
          return $('#locale_data').attr('data-USERS_REGISTRATIONS_EDIT_AVATAR_TOTAL_SIZE').strToErrorFormat();
      }
    }
  }

  // Check if any file exceeds allowed size limit
  var filesSizeValid = true;

  // Check total size of uploaded files
  var totalSizeOK = checkFilesTotalSize(fileInputs);

  _.each(fileInputs, function(fileInput) {
    var file = fileInput.files[0];
    var assetError = getFileTooBigError(file);
    var assetError = totalSizeOK;
    if (assetError) {
      renderFormError(ev, fileInput, assetError, false, "data-error='file-size'");
      filesSizeValid = false;
    }
  });
  if(filesSizeValid) {
    // Check if there is enough free space for the files
    filesSizeValid = enoughSpaceValidator(ev, fileInputs);
  }
  return filesSizeValid;
}

/*
 * Overriden in billing module for checking whether enough
 * team space is free.
 */
function enoughSpaceValidator(ev, fileInputs) {
  return true;
}
