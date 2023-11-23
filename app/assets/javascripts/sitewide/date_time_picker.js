(function() {
  'use strict';

  $(document).on('click', '[data-toggle="date-time-picker"]', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    const dt = $(this);

    if (dt.data('DateTimePicker')) {
      dt.data('DateTimePicker').show();
      return;
    }

    const linkedMin = dt.data('linked-min');
    const linkedMax =  dt.data('linked-max');

    let options = {
      ignoreReadonly: true,
      useCurrent: false
    }

    if (linkedMin) {
      if ($(linkedMin).val()) {
        options.minDate = moment($(linkedMin).val(), $(linkedMin).data('dateFormat')).toDate();
      }

      $(linkedMin).on("dp.change", function (e) {
          dt.data("DateTimePicker").minDate(e.date);
      });
    }

    if (linkedMax) {
      if ($(linkedMax).val()) {
        options.maxDate = moment($(linkedMax).val(), $(linkedMax).data('dateFormat')).toDate();
      }

      $(linkedMax).on("dp.change", function (e) {
          dt.data("DateTimePicker").maxDate(e.date);
      });
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
    if (dt.data('dateTimePicker')) {
      dt.data('dateTimePicker').clearDate();
      return;
    }

    if (!dt.data('DateTimePicker')) dt.datetimepicker({ useCurrent: false });
    dt.data('DateTimePicker').clear();
    dt.val('');
  });
}());
