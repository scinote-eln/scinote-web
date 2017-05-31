(function() {
  'use strict';

  // Show modal for repository deletion
  $(document).on('click', '#delete-repo-option', function(e) {
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

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

    return false;
  });

  // Show modal for repository renaming
  $(document).on('click', '#rename-repo-option', function(e) {
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

    var url = $(this).attr('href');
    $.ajax({
      method: 'GET',
      url: url,
      dataType: 'json'
    }).done(function(xhr, settings, data) {
      $('body').append($.parseHTML(data.responseJSON.html));
      $('#rename-repo-modal').modal('show', {
        backdrop: true,
        keyboard: false
      });
      validateRenameForm($('#rename-repo-modal'));
    });

    return false;
  });

  /**
   * Reload after successfully updated experiment
   * @param  {object} $modal Modal object
   */
  function validateRenameForm($modal) {
    if ($modal) {
      var form = $modal.find('form');
      form
      .on('ajax:success', function() {
        animateSpinner(form, true);
        location.reload();
      })
      .on('ajax:error', function(e, error) {
        var msg = JSON.parse(error.responseText);
        if ('name' in msg) {
          renderFormError(e,
                          $modal.find('#repository_name'),
                          msg.name.toString(),
                          true);
        } else {
          renderFormError(e,
                          $modal.find('#experiment-name'),
                          error.statusText,
                          true);
        }
      });
    }
  }
})();
