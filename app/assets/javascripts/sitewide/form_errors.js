// Define AJAX methods for handling errors on forms
$.fn.render_form_errors = function(model_name, errors, clear) {
  if (clear || clear === undefined) {
    this.clear_form_errors();
  }
  $(this).render_form_errors_no_clear(model_name, errors, false);
};

$.fn.render_form_errors_input_group = function(model_name, errors) {
  this.clear_form_errors();
  $(this).render_form_errors_no_clear(model_name, errors, true);
};

$.fn.render_form_errors_no_clear = function(model_name, errors, input_group) {
  var form = $(this);

  $.each(errors, function(field, messages) {
    input = $(_.filter(form.find('input, select, textarea'), function(el) {
      var name = $(el).attr('name');
      if (name) {
        return name.match(new RegExp(model_name + '\\[' + field + '\\(?'));
      }
      return false;
    }));
    input.closest('.form-group').addClass('has-error');
    var error_text = '<span class="help-block">';
    error_text += (_.map(messages, function(m) {
      return m.charAt(0).toUpperCase() + m.slice(1);
    })).join('<br />');
    error_text += '</span>';
    if (input_group) {
      input.closest('.form-group').append(error_text);
    } else {
      input.parent().append(error_text);
    }
  });
};

$.fn.clear_form_errors = function() {
  $(this).find('.nav.nav-tabs li').removeClass('has-error');
  $(this).find('.form-group').removeClass('has-error');
  $(this).find('span.help-block').remove();
};

$.fn.clear_form_fields = function() {
  $(this).find("input")
    .not("button")
    .not('input[type="submit"], input[type="reset"], input[type="hidden"]')
    .not('input[type="radio"]') // Leave out radios as this messes up Bootstrap btn-groups
    .val('')
    .removeAttr('checked')
    .removeAttr('selected');
};

// Add JavaScript client-side upload file size checking
// Callback function can be provided to be called
// any time at least one file size is too large
$.fn.add_upload_file_size_check = function(callback) {
  var $form = $(this);

  if ($form.length && $form.length > 0) {
    $form.submit(function (ev) {
       uploadFileSizeCheck(ev, callback);
    });
  }
};

function uploadFileSizeCheck(ev, callback) {
  var $fileInputs = $(ev.target.form).find("input[type='file']");
  if ($fileInputs.length && $fileInputs.length > 0) {
    var isValid = checkFilesValidity($fileInputs);

    if (!isValid) {
      // Don't submit form
      ev.preventDefault();
      ev.stopPropagation();

      if (callback) {
        callback();
      }

      return false;
    }
  }
  return true;
}

 // Show error message and mark error element and, if present, mark
 // and show the tab where the error occured.
 // NOTE: Similar to $.fn.render_form_errors, except here we process
 // one error at a time, which is not read from the form but is
 // specified manually.
function renderError(nameInput, errMsg, errAttributes) {
  var $errMsgSpan = $(nameInput).next(".help-block");
  if(!$errMsgSpan.length) {
    errAttributes = (_.isUndefined(errAttributes)) ? "" : " " + errAttributes;
    $(nameInput).after("<span class='help-block'" + errAttributes + ">" + errMsg + "</span>");
    $(nameInput).closest(".form-group").addClass("has-error");
  } else {
    $errMsgSpan.html(errMsg);
  }

  $form = $(nameInput).closest("form");
  $tab = $(nameInput).closest(".tab-pane");
  if($tab.length) {
    tabsPropagateErrorClass($form);
    $parent = $tab;
  } else {
    $parent = $form;
  }

  // Focus and scroll to the error if it is the first (most upper) one
  if($parent.find(".form-group.has-error").length === 1) {
    goToFormElement(nameInput);
  }

  event.preventDefault();
}

// If any of tabs (if exist) has errors, add has-error class to
// parent tab navigation link and show the tab (if not already)
function tabsPropagateErrorClass(parent) {
  var $contents = parent.find("div.tab-pane");
  _.each($contents, function(tab) {
    var $tab = $(tab);
    var $errorFields = $tab.find(".has-error");
    if ($errorFields.length > 0) {
      var id = $tab.attr("id");
      var navLink = parent.find("a[href='#" + id + "'][data-toggle='tab']");
      if (navLink.parent().length > 0) {
        navLink.parent().addClass("has-error");
      }
    }
  });
  $(".nav-tabs .has-error:first:not(.active) > a", parent).tab("show");
}
