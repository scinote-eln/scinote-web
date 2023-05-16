/* global I18n formatJS */
(function() {
  $('.datetime-picker-container').each(function() {
    const id = $(this).data('id');
    if (id) {
      const dt = $(`#calendar-${id}`);
      const useCurrent = $(this).data('use-current');
      dt.datetimepicker({
        useCurrent, ignoreReadonly: true, locale: I18n.locale, format: formatJS
      });
    }
  });
}());
