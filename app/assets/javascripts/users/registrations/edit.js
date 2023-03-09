(function() {
  'use strict';

  /**
   * Toggle the view/edit form visibility.
   * @param form - The jQuery form selector.
   * @param edit - True to set form to edit mode;
   * false to set form to view mode.
   */

  /* global _ filesValidator animateSpinner FileTypeEnum initShowPassword */

  var forms = $('form[data-for]');

  function toggleFormVisibility(form, edit) {
    var val = form.find("input[data-role='src']").val();
    if (edit) {
      form.find("[data-part='view']").hide();
      form.find("[data-part='edit']").show();
      form.find("[data-part='edit'] input:not([type='file']):not([type='submit']):first").focus();
      initShowPassword();
    } else {
      form.find("[data-part='view']").show();
      form.find("[data-part='edit'] input").blur();
      form.find("[data-part='edit']").hide();

      // Clear all errors on the parent form
      form.clearFormErrors();

      // Clear any neccesary fields
      form.find("input[data-role='clear']").val('');

      // Copy field data
      form.find("input[data-role='edit']").val(val);
    }
  }


  // Add "edit form" listeners
  forms.find("[data-action='edit']").click(function(ev) {
    var $form = $(this).closest('form');
    ev.preventDefault();
    // First, hide all form edits
    _.each(forms, function() {
      toggleFormVisibility($form, false);
    });

    // Then, edit the current form
    toggleFormVisibility($form, true);
  });

  // Add "cancel form" listeners
  forms.find("[data-action='cancel']").click(function(ev) {
    var $form = $(this).closest('form');
    ev.preventDefault();

    // Hide the edit portion of the form
    toggleFormVisibility($form, false);
  });

  // Add form submit listeners
  forms.not("[data-for='avatar']")
    .on('ajax:success', function() {
      // Simply reload the page
      location.reload();
    })
    .on('ajax:error', function(ev, data) {
      // Render form errors
      $(this).renderFormErrors('user', data.responseJSON);
    });

  $('#user-avatar-field :submit').click(function(ev) {
    var $form = $(ev.target.form);
    var $fileInput = $form.find('input[type=file]');
    $form.clearFormErrors();

    if (filesValidator(ev, $fileInput, FileTypeEnum.AVATAR)) {
      // Local file uploading
      animateSpinner();
    }
    $fileInput[0].value = '';
  });
}());
