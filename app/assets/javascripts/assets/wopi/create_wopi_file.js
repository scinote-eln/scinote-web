function applyCreateWopiFileCallback()  {
  $(".create-wopi-file-btn").off().on('click', function(e){
    var $modal = $('#new-office-file-modal');

    // Append element info to which the new file will be attached
    $modal.find('#element_id').val($(this).data('id'));
    $modal.find('#element_type').val($(this).data('type'));
    $modal.modal('show');

    return false;
  });
}


(function(global) {
  function initCreateWopiFileModal() {
    console.log('jeje')
    //Click on cancel button
    $("#new-office-file-modal form")
    .submit(function(e) {
      //var $form = $(this).closest("form");
      $.ajax({
        url: $btn.data('href'),
        method: 'GET',
        success: function(data) {
          var $form = $(data.html);
          animateSpinner(null, false);
          $('#results').prepend($form);
          formAjaxResultText($form);
          Results.initCancelFormButton($form, initNewReslutText);
          Results.toggleResultEditButtons(false);
          TinyMCE.refresh();
          TinyMCE.highlight();
          $('#result_name').focus();
        },
        error: function() {
          animateSpinner(null, false);
          initNewReslutText();
        }
      })
    })
  }
  initCreateWopiFileModal();
})(window);
