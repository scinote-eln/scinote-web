/* global dropdownSelector */

(function() {
  'use strict';

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

  function initTimeZoneSelector() {
    dropdownSelector.init('#time-zone-input-field', {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      onClose: function() {
        $.ajax({
          url: $('#time-zone-input-field').data('path-to-update'),
          type: 'PUT',
          dataType: 'json',
          data: { user: { time_zone: dropdownSelector.getValues('#time-zone-input-field') } },
          success: function() {
            dropdownSelector.highlightSuccess('#time-zone-input-field');
          },
          error: function() {
            dropdownSelector.highlightError('#time-zone-input-field');
          }
        });
      }
    });
  }

  function initDateFormatSelector() {
    dropdownSelector.init('#date-format-input-field', {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      onClose: function() {
        $.ajax({
          url: $('#date-format-input-field').data('path-to-update'),
          type: 'PUT',
          dataType: 'json',
          data: { user: { date_format: dropdownSelector.getValues('#date-format-input-field') } },
          success: function() {
            dropdownSelector.highlightSuccess('#date-format-input-field');
          },
          error: function() {
            dropdownSelector.highlightError('#date-format-input-field');
          }

        });
      }
    });
  }

  initTimeZoneSelector();
  initDateFormatSelector();
  notificationsSettings();
  tooltipSettings();
  initTogglableSettingsForm();
})();
