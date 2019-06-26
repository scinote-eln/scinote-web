function applyClickCallbackOnProtocolCards() {
  $('.protocol-card').off('click').on('click', function(e) {
    $.ajax({
      url: $(this).data('show-url'),
      type: 'GET',
      dataType: 'json',
      data: {
        protocol_source: $(this).data('protocol-source'),
        protocol_id: $(this).data('show-protocol-id')
      },
      beforeSend: animateSpinner($('.protocol-preview-panel'), true),
      success: function(data) {
        $('.empty-preview-panel').hide();
        $('.full-preview-panel').show();
        $('.preview-iframe').contents().find('body').html(data.html);
        animateSpinner($('.protocol-preview-panel'), false);
      },
      error: function(_error) {
        // TODO: we should probably show some alert bubble
        $('.empty-preview-panel').show();
        $('.full-preview-panel').hide();
        animateSpinner($('.protocol-preview-panel'), false);
      }
    });
    e.preventDefault();
    return false;
  });
}

applyClickCallbackOnProtocolCards();
