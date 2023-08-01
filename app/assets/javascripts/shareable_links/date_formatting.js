/* global moment */

(function() {
  $('.iso-formatted-date').each(function() {
    let text = $(this).text().trim();

    if (!text) {
      return;
    }

    $(this).text(moment(text).local().format());
  });
}());
