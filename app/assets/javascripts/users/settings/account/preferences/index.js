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
      form.find('.selectpicker').selectpicker();
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

  notificationsSettings();
  tooltipSettings();
  initTogglableSettingsForm();

  // Setup notification checkbox buttons
  function notificationsSettings() {
    var notification_settings = [ "recent_notification",
                                  "assignments_notification" ]

    for (var i = 0; i < notification_settings.length; i++ ) {
      var setting = $('[name="' + notification_settings[i] + '"]');
      var dependant = $('[name="' + notification_settings[i] + '_email"]');
      dependant.checkboxpicker({ onActiveCls: 'btn-toggle', offActiveCls: 'btn-toggle' });
      setting
        .checkboxpicker({
          onActiveCls: 'btn-toggle', offActiveCls: 'btn-toggle'
        }).change(function() {
          if ( $(this).prop('checked') ) {
            enableDependant($('[name="' + $(this).attr('name') + '_email"]'));
          } else {
            disableDependant($('[name="' + $(this).attr('name') + '_email"]'));
          }
        });

      if ( setting.attr('value') === 'true' ) {
        setting.prop('checked', true);
      } else {
        setting.prop('checked', false);
        disableDependant(dependant);
      }

      setEmailSwitch(dependant);
    }

    function setEmailSwitch(setting) {
      setting
        .checkboxpicker({
          onActiveCls: 'btn-toggle', offActiveCls: 'btn-toggle'
        });
      if ( setting.attr('value') === 'true' ) {
        setting.prop('checked', true);
        enableDependant(setting);
      } else {
        setting.prop('checked', false);
      }
    }

    function disableDependant(dependant) {
      dependant.checkboxpicker().prop('disabled', true);
      dependant.checkboxpicker().prop('checked', false);
    }

    function enableDependant(dependant) {
      dependant.checkboxpicker().prop('disabled', false);
    }

    // Initialize system messages
    var system_message_notification = $('[name="system_message_notification"]');
    system_message_notification
      .checkboxpicker({
        onActiveCls: 'btn-toggle', offActiveCls: 'btn-toggle'
      });
    system_message_notification.prop('checked', true);
    system_message_notification.prop('disabled', true);

    // Initialize system messages email
    var system_message_notification_mail = $('[name="system_message_notification_email"]');
    system_message_notification_mail
      .checkboxpicker({
        onActiveCls: 'btn-toggle', offActiveCls: 'btn-toggle'
      });
    system_message_notification_mail.prop(
      'checked',
      system_message_notification_mail.attr('value') === 'true'
    );
  }

// Initialize tooltips settings form
  function tooltipSettings() {
    var toggleInput = $('[name="tooltips_enabled"]');
    toggleInput
      .checkboxpicker({ onActiveCls: 'btn-toggle', offActiveCls: 'btn-toggle' });

    if (toggleInput.attr('value') === 'true') {
      toggleInput.prop('checked', true);
    } else {
      toggleInput.prop('checked', false);
    }
  }

  // triggers submit action when the user clicks
  function initTogglableSettingsForm() {
    $('#togglable-settings-panel')
      .find('.btn-group')
      .on('click', function() {
        $(this).submit();
      });
  }
})();
