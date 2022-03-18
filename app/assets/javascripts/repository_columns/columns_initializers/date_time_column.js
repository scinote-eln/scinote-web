/* global dropdownSelector */
/* eslint-disable no-unused-vars */
var RepositoryDateTimeColumnType = (function() {
  const columnContainer = '.datetime-column-type';

  function initReminderUnitDropdown() {
    dropdownSelector.init('.datetime-column-type .reminder-unit', {
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

    $modal.on('change', `${columnContainer} #datetime-reminder, ${columnContainer} #datetime-range`, function() {
      let reminderCheckbox = $(columnContainer).find('#datetime-reminder');
      let rangeCheckbox = $(columnContainer).find('#datetime-range');
      rangeCheckbox.attr('disabled', reminderCheckbox.is(':checked'));
      reminderCheckbox.attr('disabled', rangeCheckbox.is(':checked'));
      $(columnContainer).find('.reminder-group').toggleClass('hidden', !reminderCheckbox.is(':checked'));
    });

    $modal.on('columnModal::partialLoadedForRepositoryDateTimeValue', function() {
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
      var isRange = $('#datetime-range').is(':checked');
      var columnType = $('#repository-column-data-type').val();
      if (isRange) {
        columnType = columnType.replace('Value', 'RangeValue');
      }
      return {
        column_type: columnType,
        reminder_delta: $(columnContainer).find('.reminder-delta').val(),
        reminder_value: $(columnContainer).find('.reminder-value').val(),
        reminder_unit: $(columnContainer).find('.reminder-unit').val(),
        reminder_message: $(columnContainer).find('.reminder-message').val()
      };
    }
  };
}());
