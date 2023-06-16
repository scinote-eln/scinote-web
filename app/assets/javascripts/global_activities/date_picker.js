/* global I18n */
(function() {
  $('.datetime-picker-container').each(function() {
    const id = $(this).data('id');
    if (id) {
      const dt = $(`#calendar-${id}`);
      const useCurrent = $(this).data('use-current');
      const formatJS = $(this).data('datetime-picker-format');
      dt.datetimepicker({
        useCurrent, ignoreReadonly: true, locale: I18n.locale, format: formatJS
      });
    }
  });
}());
