(function() {
  'use strict';

  $('#search_whole_word').click(function() {
    if ($(this).prop('checked') === true) {
      $('#search_whole_phrase').prop('checked', false);
    }
  });
  $('#search_whole_phrase').click(function() {
    if ($(this).prop('checked') === true) {
      $('#search_whole_word').prop('checked', false);
    }
  });
}());
