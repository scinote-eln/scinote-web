/* global GLOBAL_CONSTANTS dropdownSelector */
/* eslint-disable no-unused-vars */
var RepositoryDateTimeColumnType = (function() {
  const columnContainer = '.datetime-column-type';

  function initReminderUnitDropdown() {
    dropdownSelector.init('.datetime-column-type .reminder-unit', {
      noEmptyOption: true,
      singleSelect: true,
      selectAppearance: 'simple',
      closeOnSelect: true,
      title: `datetime reminder unit select`
    });
  }

  function setReminderDelta() {
    let reminderValueInput = $(columnContainer).find('.reminder-value');
    reminderValueInput.val(reminderValueInput.val().replace(/[^0-9]/, ''));
    let value = reminderValueInput.val();

    if (!isNaN(parseInt(value, 10))) {
      $(columnContainer).find('.reminder-delta').val(
        value * $(columnContainer).find('.reminder-unit').val()
      );
    }
  }

  function initReminders() {
    let $modal = $('#manage-repository-column');
    $modal.on('input', `${columnContainer} .reminder-value, ${columnContainer} .reminder-unit`, function() {
      setReminderDelta();
    });

    $modal.on('change', `${columnContainer} #datetime-reminder, ${columnContainer} #datetime-range`, function() {
      let reminderCheckbox = $(columnContainer).find('#datetime-reminder');
      let rangeCheckbox = $(columnContainer).find('#datetime-range');
      rangeCheckbox.attr('disabled', reminderCheckbox.is(':checked'));
      reminderCheckbox.attr('disabled', rangeCheckbox.is(':checked'));
      $(columnContainer).find('.reminder-group').toggleClass('hidden', !reminderCheckbox.is(':checked'));
      if (reminderCheckbox.is(':checked')) setReminderDelta();
    });

    $modal.on('columnModal::partialLoadedForRepositoryDateTimeValue', function() {
      initReminderUnitDropdown();
      $('#datetime-reminder-message').on('input', function() {
        $(this).closest('.sci-input-container').toggleClass(
          'error',
          this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
        );
        $('#update-repo-column-submit').toggleClass(
          'disabled',
          this.value.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH
        );
      });
    });
  }

  return {
    init: () => {
      initReminders();
    },
    checkValidation: () => {
      let reminderValueInput = $(columnContainer).find('.reminder-value');
      if (parseInt(reminderValueInput.val(), 10) > parseInt(reminderValueInput.data('max'), 10)) {
        reminderValueInput.parent().addClass('error');
        return false;
      }

      return true;
    },
    initReminderUnitDropdown: () => {
      initReminderUnitDropdown();
    },
    loadParams: () => {
      let isRange = $('#datetime-range').is(':checked');
      let hasReminder = $('#datetime-reminder').is(':checked');
      let columnType = $('#repository-column-data-type').val();
      if (isRange) {
        columnType = columnType.replace('Value', 'RangeValue');
      }
      return {
        column_type: columnType,
        reminder_delta: hasReminder ? $(columnContainer).find('.reminder-delta').val() : null,
        reminder_value: hasReminder ? $(columnContainer).find('.reminder-value').val() : null,
        reminder_unit: hasReminder ? $(columnContainer).find('.reminder-unit').val() : null,
        reminder_message: hasReminder ? $(columnContainer).find('.reminder-message').val() : null
      };
    }
  };
}());
