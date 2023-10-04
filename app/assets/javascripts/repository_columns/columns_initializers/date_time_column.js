/* global GLOBAL_CONSTANTS dropdownSelector */
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
    $modal.on('change', `${columnContainer} #datetime-reminder, ${columnContainer} #datetime-range`, function() {
      let reminderCheckbox = $(columnContainer).find('#datetime-reminder');
      let rangeCheckbox = $(columnContainer).find('#datetime-range');
      const isExistingRecord = $('#new-repo-column-submit').css('display') === 'none';
      rangeCheckbox.attr('disabled', isExistingRecord || reminderCheckbox.is(':checked'));
      reminderCheckbox.attr('disabled', rangeCheckbox.is(':checked'));
      $(columnContainer).find('.reminder-group').toggleClass('hidden', !reminderCheckbox.is(':checked'));
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
        reminder_value: hasReminder ? $(columnContainer).find('.reminder-value').val() : null,
        reminder_unit: hasReminder ? $(columnContainer).find('.reminder-unit').val() : null,
        reminder_message: hasReminder ? $(columnContainer).find('.reminder-message').val() : null
      };
    }
  };
}());
