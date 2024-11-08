/* global */

(function () {
  $('.rtf-view').toArray().forEach((rtf) => {
    $(rtf).find('table').toArray().forEach((table) => {
      if ($(table).parents('table').length === 0) {
        $(table).css('float', 'none')
          .wrapAll('<div class="table-wrapper w-full" style="overflow: auto"></div>');
      }
    });
  });
}());
