/* Global selectors */
var modal = $("#add-user-modal");
var modalContent = modal.find(".modal-content");
var invitingExisting = true;
var inviteButton = $("[data-id='invite-btn']");
var inviteLinks = $("[data-action='invite']");
var inviteExistingCollapsible = $("#invite-existing");
var inviteExistingForm = $("[data-id='invite-existing-form']");
var inviteExistingQuery = $("#existing_query");
var inviteExistingResults = $("#invite-existing-results");
var inviteNewCollapsible = $("#invite-new");
var inviteNewForm = $("[data-id='invite-new-form']");
var inviteNewRoleInput = $("[data-id='new-user-role-input']");
var inviteNewNameInput = $("[data-id='invite-new-name-input']");
var inviteNewEmailInput = $("[data-id='invite-new-email-input']");

function disableInviteBtn() {
  inviteButton.attr("disabled", "disabled");
}
function enableInviteBtn() {
  inviteButton.removeAttr("disabled");
}

/**
 * General modal configuration & toggling.
 */
modal
.on("shown.bs.modal", function() {
  // Focus the invite existing input
  inviteExistingQuery.focus();
  invitingExisting = true;
})
.on("hidden.bs.modal", function() {
  // Disable invite button,
  // reset forms, reset rendered content
  disableInviteBtn();
  inviteExistingForm.clearFormFields();
  inviteExistingForm.clearFormErrors();
  inviteExistingResults.html("");
  inviteNewForm.clearFormFields();
  inviteNewForm.clearFormErrors();
});

inviteExistingCollapsible
.on("hidden.bs.collapse", function() {
  // Reset form & rendered content
  inviteExistingForm.clearFormFields();
  inviteExistingForm.clearFormErrors();
  inviteExistingResults.html("");
})
.on("hide.bs.collapse", function() {
  // Disable invite button
  disableInviteBtn();
})
.on("shown.bs.collapse", function() {
  // Focus input when collapsible is shown
  inviteExistingQuery.focus();
  invitingExisting = true;
});

inviteNewCollapsible
.on("hidden.bs.collapse", function() {
  // Reset form
  inviteNewForm.clearFormFields();
  inviteNewForm.clearFormErrors();
})
.on("hide.bs.collapse", function() {
  // Disable invite button
  disableInviteBtn();
})
.on("shown.bs.collapse", function() {
  // Focus input when collapsible is shown
  inviteNewNameInput.focus();
  invitingExisting = false;
});

// Invite links simply submit either of the forms
inviteLinks.on("click", function() {
  var $this = $(this);

  if (invitingExisting) {
    var form =
      inviteExistingResults
      .find("form[data-id='create-user-organization-form']");

    // Set the role value in the form
    form
    .find("[data-id='existing-user-role-input']")
    .attr("value", $this.attr("data-value"));

    // Submit the form inside "invite existing"
    animateSpinner(modalContent);
    form.submit();
  } else {
    // Set the role value in the form
    inviteNewRoleInput
    .attr("value", $this.attr("data-value"));

    // Submit the form inside "invite new"
    animateSpinner(modalContent);
    inviteNewForm.submit();
  }
});

/**
 * Invite existing user functionality.
 */

// Invite existing form submission
modal
.on("ajax:success", inviteExistingForm.selector, function(ev, data, status) {
  // Clear form errors
  inviteExistingForm.clearFormErrors();

  // Alright, render the html
  inviteExistingResults.html(data.html);

  // Disable invite button
  disableInviteBtn();
})
.on("ajax:error", inviteExistingForm.selector, function(ev, data, status) {
    // Display form errors
    inviteExistingForm.renderFormErrors("", data.responseJSON);
});

// Update values & enable "invite" button
// when user clicks on existing user
inviteExistingResults
.on("change", "[data-action='select-existing-user']", function() {
  var $this = $(this);
  // Set the hidden input user ID
  $("[data-id='existing-user-id-input']")
  .attr("value", $this.attr("data-user-id"));

  // Enable button
  enableInviteBtn();
});

/**
 * Invite new user functionality.
 */

inviteNewForm
.on("ajax:success", function(ev, data, status) {
  // Reload the page
  location.reload();
})
.on("ajax:error", function(ev, data, status) {
  // Render form errors
  animateSpinner(modalContent, false);
  $(this).renderFormErrors("user", data.responseJSON);
});


// Enable/disable invite button depending whether
// any of the new user inputs are empty
inviteNewForm
.on("input", "input[data-role='input']", function() {
  if (
    _.isEmpty(inviteNewNameInput.val()) ||
    _.isEmpty(inviteNewEmailInput.val())
  ) {
    disableInviteBtn();
  } else {
    enableInviteBtn();
  }
});

