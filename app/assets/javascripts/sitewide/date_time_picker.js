(function() {
  'use strict';

  $(document).on('click', '[data-toggle="date-time-picker"]', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    let dt = $(this);

    if (dt.data('DateTimePicker')) {
      dt.data('DateTimePicker').destroy();
    }

    dt.datetimepicker({ ignoreReadonly: true });
    dt.data('DateTimePicker').show();
  });

  $(document).on('click', '[data-toggle="clear-date-time-picker"]', function() {
    let dt = $(`#${$(this).data('target')}`);
    if (!dt.data('DateTimePicker')) dt.datetimepicker({ useCurrent: false });
    dt.data('DateTimePicker').clear();
    dt.val('');
  });
}());
