(function() {
  'use strict';

  /**
   * Show modal on link click and handle its' validation
   * @param  {object} $linkToModals Link objects for opening the modal
   * @param  {string} modalID       Modal ID
   */
  function initializeModal($linkToModal, modalID) {
    $linkToModal
      .on('ajax:beforeSend', function() {
        animateSpinner();
      })
      .on('ajax:success', function(e, data) {
        // Add and show modal
        $('body').append($.parseHTML(data.html));
        $(modalID).modal('show', {
          backdrop: true,
          keyboard: false
        });

        validateRenameForm($(modalID));

        // Remove modal when it gets closed
        $(modalID).on('hidden.bs.modal', function() {
          $(modalID).remove();
        });
      })
      .on('ajax:error', function() {
        // TODO
      })
      .on('ajax:complete', function() {
        animateSpinner(null, false);
      });
  }

  /**
   * Rename form validation
   * @param  {object} $modal Modal object
   */
  function validateRenameForm($modal) {
    if ($modal) {
      var form = $modal.find('form');
      form
      .on('ajax:success', function(ev, data) {
        animateSpinner(form, true);
        $(location).attr('href', data.url);
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
                          $modal.find('#repository_name'),
                          error.statusText,
                          true);
        }
      });
    }
  }

  initializeModal($('.delete-repo-option'), '#delete-repo-modal');
  initializeModal($('.rename-repo-option'), '#rename-repo-modal');
})();
