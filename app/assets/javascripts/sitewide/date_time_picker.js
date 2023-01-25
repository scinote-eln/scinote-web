(function() {
  'use strict';

  $(document).on('click', '[data-toggle="date-time-picker"]', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    let dt = $(this);
    let options = { ignoreReadonly: true };

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
