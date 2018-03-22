(function() {
  'use strict';

  function initEditCoumnModal() {}

  function initDeleteColumnModal() {
    $('[data-action="destroy"]').on('click', function() {
      var element = $(this);
      var modal_html = $("#deleteRepositoryColumn");
      $.get(element.closest('li').attr('data-destroy-url'), function(data) {
        modal_html.find('.modal-body').html(data.html)
                                                .promise()
                                                .done(function() {
          modal_html.modal('show');
          initSubmitAction(modal_html, $(modal_html.find('form')));
        });

      })
    });
  }

  function initSubmitAction(modal, form) {
    modal.find('[data-action="delete"]').on('click', function() {
      form.submit();
      modal.modal('hide')
      animateSpinner();
      processResponse(form);
    });
  }


  function processResponse(form) {
    form.on('ajax:success', function(e, data) {
      $('.list-group-item[data-id="' + data.id + '"]').remove();
      HelperModule.flashAlertMsg(data.message, 'success');
      animateSpinner(null, false);
    }).on('ajax:error', function(e, xhr, status, error) {
      HelperModule.flashAlertMsg(error.message, 'danger');
      animateSpinner(null, false);
    })
  }

  $(document).ready(function() {
    initEditCoumnModal();
    initDeleteColumnModal();
  })
})()
