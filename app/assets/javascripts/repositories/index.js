(function() {
  'use strict';

  // Show modal for repository deletion
  $(document).on('click', '#delete-repo-option', function() {
    var url = $(this).attr('href');
    $.ajax({
      method: 'GET',
      url: url,
      dataType: 'json'
    }).done(function(xhr, settings, data) {
      $('body').append($.parseHTML(data.responseJSON.html));
      $('#delete-repo-modal').modal('show', {
        backdrop: true,
        keyboard: false
      });
    });
  });
})();
