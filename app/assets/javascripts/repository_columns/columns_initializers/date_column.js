/* global GLOBAL_CONSTANTS dropdownSelector */
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
    $modal.on('change', `${columnContainer} #date-reminder, ${columnContainer} #date-range`, function() {
      let reminderCheckbox = $(columnContainer).find('#date-reminder');
      let rangeCheckbox = $(columnContainer).find('#date-range');
      const isExistingRecord = $('#new-repo-column-submit').css('display') === 'none';
      rangeCheckbox.attr('disabled', isExistingRecord || reminderCheckbox.is(':checked'));
      reminderCheckbox.attr('disabled', rangeCheckbox.is(':checked'));
      $(columnContainer).find('.reminder-group').toggleClass('hidden', !reminderCheckbox.is(':checked'));
    });

    $modal.on('columnModal::partialLoadedForRepositoryDateValue', function() {
      initReminderUnitDropdown();
      $('#date-reminder-message').on('input', function() {
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
      var isRange = $('#date-range').is(':checked');
      let hasReminder = $('#date-reminder').is(':checked');
      var columnType = $('#repository-column-data-type').val();
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
