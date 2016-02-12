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
    form.clear_form_errors();

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
  var form = $(this).closest("form");

  // First, hide all form edits
  _.each(forms, function(form) {
    toggleFormVisibility($(form), false);
  });

  // Then, edit the current form
  toggleFormVisibility(form, true);
});

// Add "cancel form" listeners
forms
.find("[data-action='cancel']").click(function() {
  var form = $(this).closest("form");

  // Hide the edit portion of the form
  toggleFormVisibility(form, false);
});

// Add form submit listeners
forms
.on("ajax:success", function(ev, data, status) {
  // Simply reload the page
  location.reload();
})
.on("ajax:error", function(ev, data, status) {
  // Render form errors
  $(this).render_form_errors("user", data.responseJSON);
});

// Add upload file size checking
$("form[data-for='avatar']").add_upload_file_size_check();

// S3 direct uploading
function startFileUpload(ev, btn) {
  var form = btn.form;
  var $form = $(form);
  var fileInput = $form.find("input[type=file]").get(0);
  var url = "/avatar_signature.json";

  $form.clear_form_errors();
  animateSpinner($form);

  directUpload(form, null, url, function (assetId) {
    var file = fileInput.files[0];
    fileInput.type = "hidden";
    fileInput.name = fileInput.name.replace("[avatar]", "[avatar_file_name]");
    fileInput.value = file.name;

    $("#user_change_avatar").remove();

    btn.onclick = null;
    $(btn).click();
    animateSpinner($form, false);
  }, function (errors) {
    $form.render_form_errors("user", errors);

    var avatarError;

    animateSpinner($form, false);
    for (var c in errors) {
      if (/^avatar/.test(c)) {
        avatarError = errors[c];
        break;
      }
    }

    if (avatarError) {
      var $el = $form.find("input[type=file]");

      $form.clear_form_errors();
      $el.closest(".form-group").addClass("has-error");
      $el.parent().append("<span class='help-block'>" + avatarError + "</span>");
    }
  }, "avatar");

  ev.preventDefault();
}


