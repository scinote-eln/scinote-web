(function(){
  'use strict';
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
    $(this).renderFormErrors("user", data.responseJSON);
  });

  var repeatTutorialModal = $("#repeat-tutorial-modal");
  var repeatTutorialModalBody = repeatTutorialModal.find(".modal-body");
  initRepeatTutorialModal();
  notificationsSettings();
  initNotificationSettingsForm();

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

  // Setup notification checkbox buttons
  function notificationsSettings() {
    var recent_notification = $('[name="recent_notification"]');
    recent_notification
      .checkboxpicker({
        onActiveCls: 'btn-primary'
      });

    if ( recent_notification.attr('value') === 'true' ) {
      recent_notification.prop('checked', true);
    } else {
      recent_notification.prop('checked', false);
    }

    var assignments_notification = $('[name="assignments_notification"]');
    assignments_notification
      .checkboxpicker({
        onActiveCls: 'btn-primary'
      });

    if ( assignments_notification.attr('value') === 'true' ) {
      assignments_notification.prop('checked', true);
    } else {
      assignments_notification.prop('checked', false);
    }

    var system_message_notification = $('[name="system_message_notification"]');
    system_message_notification
      .checkboxpicker({
        onActiveCls: 'btn-primary'
      });
    system_message_notification.prop('checked', true);
    system_message_notification.prop('disabled', true);
  }

  // triggers submit action when the user clicks
  function initNotificationSettingsForm() {
    $('#notifications-settings-panel')
      .find('.btn-group')
      .on('click', function() {
        $(this).submit();
      });
  }
})();
