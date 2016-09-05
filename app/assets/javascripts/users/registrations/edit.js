/**
 * Toggle the view/edit form visibility.
 * @param form - The jQuery form selector.
 * @param edit - True to set form to edit mode;
 * false to set form to view mode.
 */
function toggleFormVisibility(form, edit) {
  if (edit) {
    form.find("[data-part='view']").hide();
    form.find("[data-part='edit']").show();
    form.find("[data-part='edit'] input:not([type='file']):not([type='submit']):first").focus();
  } else {
    form.find("[data-part='view']").show();
    form.find("[data-part='edit'] input").blur();
    form.find("[data-part='edit']").hide();

    // Clear all errors on the parent form
    form.clearFormErrors();

    // Clear any neccesary fields
    form.find("input[data-role='clear']").val("");

    // Copy field data
    var val = form.find("input[data-role='src']").val();
    form.find("input[data-role='edit']").val(val);
  }
}

var forms = $("form[data-for]");

// Add "edit form" listeners
forms
.find("[data-action='edit']").click(function() {
  var $form = $(this).closest("form");

  // First, hide all form edits
  _.each(forms, function(form) {
    toggleFormVisibility($form, false);
  });

  // Then, edit the current form
  toggleFormVisibility($form, true);
});

// Add "cancel form" listeners
forms
.find("[data-action='cancel']").click(function() {
  var $form = $(this).closest("form");

  // Hide the edit portion of the form
  toggleFormVisibility($form, false);
});

// Add form submit listeners
forms
.not("[data-for='avatar']")
.on("ajax:success", function(ev, data, status) {
  // Simply reload the page
  location.reload();
})
.on("ajax:error", function(ev, data, status) {
  // Render form errors
  $(this).renderFormErrors("user", data.responseJSON);
});

function processFile(ev, forS3) {
  var $form = $(ev.target.form);
  $form.clearFormErrors();

  var $fileInput = $form.find("input[type=file]");
  if(filesValidator(ev, $fileInput, FileTypeEnum.AVATAR)) {
    if(forS3) {
      // Redirects file uploading to S3
      var url = "/avatar_signature.json";
      directUpload(ev, url, true);
    } else {
      // Local file uploading
      animateSpinner();
    }
  }
}
