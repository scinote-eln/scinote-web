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
        resetPreviewPanel();
        animateSpinner($('.protocol-preview-panel'), false);
      }
    });
    e.preventDefault();
    return false;
  });
}

// Resets preview to the default state
function resetPreviewPanel() {
  $('.empty-preview-panel').show();
  $('.full-preview-panel').hide();
}

function setDefaultViewState() {
  resetPreviewPanel();
  $('.empty-text').show();
  $('.list-wrapper').hide();
}

// Apply AJAX callbacks onto the search box
function applySearchCallback() {
  // Submit form on every input in the search box
  $('input[name="key"]').off('input').on('input', function() {
    $('form.protocols-search-bar').submit();
  });

  // Submit form when clicking on sort buttons
  $('input[name="sort_by"]').off('change').on('change', function () {
    $('form.protocols-search-bar').submit();
  });

  // Bind ajax calls on the form
  $('form.protocols-search-bar').off('ajax:success').off('ajax:error')
    .bind('ajax:success', function(evt, data, status, xhr) {
      if (data.html) {
        resetPreviewPanel();
        $('.empty-text').hide();
        $('.list-wrapper').show();

        $('.list-wrapper').html(data.html)
        applyClickCallbackOnProtocolCards();
      } else {
        setDefaultViewState();
      }
    })
    .bind("ajax:error", function(evt, xhr, status, error) {
      setDefaultViewState();

      console.log(xhr.responseText);
    });
}

applySearchCallback();
