$(document).on('click', '.barcode-scanner', function() {
  var search = $('.search-container .search-field');
  var input = $('<input>').attr('type', 'text').css('opacity', 0).appendTo('body');
  search.val('');
  search.attr('disabled', true).addClass('barcode-mode');

  input.focus();
  input.one('change', function() {
    search.val($(this).val());
    search.trigger('keyup');
    $(document).click();
  });

  setTimeout(function() {
    $(document).one('click', function() {
      search.attr('disabled', false).removeClass('barcode-mode');
      input.remove();
    });
  });
});
