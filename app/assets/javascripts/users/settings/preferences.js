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

var repeatTutorialModal = $("#repeat-tutorial-modal");
var repeatTutorialModalBody = repeatTutorialModal.find(".modal-body");
initRepeatTutorialModal();

$("#reset-tutorial-btn")
  .on("ajax:before", function () {
    repeatTutorialModal.modal('show');
  })

  .on("ajax:success", function (e, data) {
    initRepeatTutorialModalBody(data);
  });

function initRepeatTutorialModal() {
// Remove modal content when modal window is closed.
  repeatTutorialModal.on("hidden.bs.modal", function () {
    repeatTutorialModalBody.html("");
  });
}

// Initialize ajax listeners and elements style on modal body. This
// function must be called when modal body is changed.
function initRepeatTutorialModalBody(data) {
  repeatTutorialModalBody.html(data.html);
  repeatTutorialModalBody.find(".selectpicker").selectpicker();
}