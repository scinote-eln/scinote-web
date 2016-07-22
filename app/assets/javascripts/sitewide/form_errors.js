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

 // Show error message and mark error input (if errMsg is defined)
 // and, if present, mark and show the tab where the error occured,
 // and go to the input, if it is the most upper one or if errMsg is
 // undefined
 // NOTE: Similar to $.fn.render_form_errors, except here we process
 // one error at a time, which is not read from the form but is
 // specified manually.
function renderFormError(nameInput, errMsg, errAttributes) {
  if(!_.isUndefined(errMsg)) {
    var $errMsgSpan = $(nameInput).next(".help-block");
    errAttributes = _.isUndefined(errAttributes) ? "" : " " + errAttributes;
    if (!$errMsgSpan.length) {
      $(nameInput).closest(".form-group").addClass("has-error");
    }
    $(nameInput).after("<span class='help-block'" + errAttributes + ">" + errMsg + "</span>");
  }

  $form = $(nameInput).closest("form");
  $tab = $(nameInput).closest(".tab-pane");
  if ($tab.length) {
    tabsPropagateErrorClass($form);
    $parent = $tab;
  } else {
    $parent = $form;
  }

  // Focus and scroll to the error if it is the first (most upper) one
  if ($parent.find(".form-group.has-error").length === 1 || _.isUndefined(errMsg)) {
    goToFormElement(nameInput);
  }

  event.preventDefault();
}

// If any of tabs (if exist) has errors, mark parent tab
// navigation link and show the tab (if not already)
function tabsPropagateErrorClass($form) {
  var $contents = $form.find("div.tab-pane");
  _.each($contents, function(tab) {
    var $tab = $(tab);
    var $errorFields = $tab.find(".has-error");
    if ($errorFields.length) {
      var id = $tab.attr("id");
      var navLink = $form.find("a[href='#" + id + "'][data-toggle='tab']");
      if (navLink.parent().length) {
        navLink.parent().addClass("has-error");
      }
    }
  });
  $(".nav-tabs .has-error:first:not(.active) > a", $form).tab("show");
}
