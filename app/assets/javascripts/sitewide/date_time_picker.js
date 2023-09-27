(function() {
  'use strict';

  $(document).on('click', '[data-toggle="date-time-picker"]', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    let dt = $(this);
    let selectedDate = {};

    $('.calendar-input').slice(0, 2).each(function(index, element) {
      if ($(element).val().length > 0 ) {
        selectedDate.index = index;
        selectedDate.date = moment($(element).val(), element.dataset.dateFormat).toDate();
      }
    });

    let options = {
      ignoreReadonly: true
    };

    if (selectedDate.date) {
      if (selectedDate.index == 0) {
        options.minDate = selectedDate.date;
      } else if (selectedDate.index == 1) {
        options.maxDate = selectedDate.date;
      }
    }

    if (dt.data('DateTimePicker')) {
      dt.data('DateTimePicker').destroy();
    }

    if (dt.data('positioningVertical')) {
      options.widgetPositioning = { vertical: dt.data('positioningVertical') };
    }

    dt.datetimepicker(options);
    dt.data('DateTimePicker').show();
  });

  $(document).on('mousedown', '[data-toggle="clear-date-time-picker"]', function() {
    let dt = $(`#${$(this).data('target')}`);
    if (!dt.data('DateTimePicker')) dt.datetimepicker({ useCurrent: false });
    dt.data('DateTimePicker').clear();
    dt.val('');
  });
}());
