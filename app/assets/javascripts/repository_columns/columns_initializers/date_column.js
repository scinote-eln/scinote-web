/* global dropdownSelector */
/* eslint-disable no-unused-vars */
var RepositoryDateColumnType = (function() {
  const columnContainer = '.date-column-type';

  function initReminderUnitDropdown() {
    dropdownSelector.init('.date-column-type .reminder-unit', {
      noEmptyOption: true,
      singleSelect: true,
      selectAppearance: 'simple',
      closeOnSelect: true
    });
  }

  function initReminders() {
    let $modal = $('#manage-repository-column');
    $modal.on('change', `${columnContainer} .reminder-value, ${columnContainer} .reminder-unit`, function() {
      let value = $(columnContainer).find('.reminder-value').val();
      if (!isNaN(parseFloat(value))) {
        $(columnContainer).find('.reminder-delta').val(
          value * $(columnContainer).find('.reminder-unit').val()
        );
      }
    });

    $modal.on('change', `${columnContainer} #date-reminder, ${columnContainer} #date-range`, function() {
      let reminderCheckbox = $(columnContainer).find('#date-reminder');
      let rangeCheckbox = $(columnContainer).find('#date-range');
      rangeCheckbox.attr('disabled', reminderCheckbox.is(':checked'));
      reminderCheckbox.attr('disabled', rangeCheckbox.is(':checked'));
      $(columnContainer).find('.reminder-group').toggleClass('hidden', !reminderCheckbox.is(':checked'));
    });

    $modal.on('columnModal::partialLoadedForRepositoryDateValue', function() {
      initReminderUnitDropdown();
    });
  }

  return {
    init: () => {
      initReminders();
    },
    checkValidation: () => {
      return true;
    },
    initReminderUnitDropdown: () => {
      initReminderUnitDropdown();
    },
    loadParams: () => {
      var isRange = $('#date-range').is(':checked');
      let hasReminder = $('#date-reminder').is(':checked');
      var columnType = $('#repository-column-data-type').val();
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
