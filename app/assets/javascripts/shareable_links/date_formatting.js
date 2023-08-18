/* global moment */

(function() {
  $('.iso-formatted-date').each(function() {
    const userLang = navigator.language || navigator.userLanguage || 'en-US';
    let text = $(this).text().trim();

    if (!text) {
      return;
    }

    $(this).text(moment(text).local(userLang).format('LLL'));
  });
}());
