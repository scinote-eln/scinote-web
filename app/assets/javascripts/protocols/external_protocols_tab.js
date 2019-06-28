function applyClickCallbackOnProtocolCards() {
  $('.protocol-card').off('click').on('click', function(e) {
    var currProtocolCard = $(this);

    // Check whether this card is already active and deactivate it
    if ($(currProtocolCard).hasClass('active')) {
      resetPreviewPanel();
      $(currProtocolCard).removeClass('active');
    } else {
      $('.protocol-card').removeClass('active');
      currProtocolCard.addClass('active');

      $.ajax({
        url: $(currProtocolCard).data('show-url'),
        type: 'GET',
        dataType: 'json',
        data: {
          protocol_source: $(currProtocolCard).data('protocol-source'),
          protocol_id: $(currProtocolCard).data('show-protocol-id')
        },
        beforeSend: animateSpinner($('.protocol-preview-panel'), true),
        success: function(data) {
          $('.empty-preview-panel').hide();
          $('.full-preview-panel').show();
          $('.btn-holder').html($(currProtocolCard).find('.external-import-btn').clone());
          $('.preview-iframe').contents().find('body').html(data.html);

          initLoadProtocolModalPreview();
          animateSpinner($('.protocol-preview-panel'), false);
        },
        error: function(_error) {
          // TODO: we should probably show some alert bubble
          resetPreviewPanel();
          animateSpinner($('.protocol-preview-panel'), false);
        }
      });
    }
    e.preventDefault();
    return false;
  });
}

// Resets preview to the default state
function resetPreviewPanel() {
  $('.empty-preview-panel').show();
  $('.full-preview-panel').hide();
}

// Reset whole view to the default state
function setDefaultViewState() {
  resetPreviewPanel();
  $('.empty-text').show();
  $('.list-wrapper').hide();
}

// Apply AJAX callbacks onto the search box
function applySearchCallback() {
  var timeout;

  // Submit form on every input in the search box
  $('input[name="key"]').off('input').on('input', function() {
    if (timeout) {
      clearTimeout(timeout);
    }

    timeout = setTimeout(function() {
      $('form.protocols-search-bar').submit();
    }, 500);
  });

  // Submit form when clicking on sort buttons
  $('input[name="sort_by"]').off('change').on('change', function() {
    $('form.protocols-search-bar').submit();
  });

  // Bind ajax calls on the form
  $('form.protocols-search-bar').off('ajax:success').off('ajax:error')
    .bind('ajax:success', function(evt, data, status, xhr) {
      if (data.html) {
        resetPreviewPanel();
        $('.empty-text').hide();
        $('.list-wrapper').show();

        $('.list-wrapper').html(data.html);
        applyClickCallbackOnProtocolCards();
        initLoadProtocolModalPreview();
      } else {
        setDefaultViewState();
      }
    })
    .bind("ajax:error", function(evt, xhr, status, error) {
      setDefaultViewState();

      console.log(xhr.responseText);
    });
}

function resetFormErrors(modal) {
  // Reset all errors
  modal.find('form > .form-group.has-error').removeClass('has-error');
  modal.find('form > .form-group>span.help-block').html('');
  modal.find('.general-error > span').html('');
}

function showFormErrors(modal, errors) {
  resetFormErrors(modal);

  // AR valdiation errors
  Object.keys(errors.protocol).forEach(function(key) {
    var input = modal.find('#protocol_' + key);
    var msg;
    msg = key.charAt(0).toUpperCase() + key.slice(1) + ': ' + errors.protocol[key].join(', ');
    if ((input.length > 0) && (errors.protocol[key].length > 0)) {
      input.parent().next('span.help-block').html(msg);
      input.parent().parent().addClass('has-error');
    } else if (errors.protocol[key].length > 0) {
      modal.find('.general-error > span').append(msg + '<br/>');
    }
  });
}

function renderTable(table) {
  $(table).handsontable('render');
  // Yet another dirty hack to solve HandsOnTable problems
  if (parseInt($(table).css('height'), 10) < parseInt($(table).css('max-height'), 10) - 30) {
    $(table).find('.ht_master .wtHolder').css({ height: '100%', width: '100%' });
  }
}

// Expand all steps
function expandAllSteps() {
  $('.step .panel-collapse').collapse('show');
  $(document).find("[data-role='step-hot-table']").each(function() {
    renderTable($(this));
  });
  $(document).find('span.collapse-step-icon').each(function() {
    $(this).addClass('fa-caret-square-up');
    $(this).removeClass('fa-caret-square-down');
  });
}

function handleFormSubmit(modal) {
  var form = modal.find('form');
  form.on('submit', function(e) {
    var url = form.attr('action');
    e.preventDefault(); // avoid to execute the actual submit of the form.
    e.stopPropagation();
    animateSpinner(modal, true);
    $.ajax({
      type: 'POST',
      url: url,
      data: form.serialize(), // serializes the form's elements.
      success: function(data) {
        animateSpinner(modal, false);
        window.location.replace(data.redirect_url);
      },
      error: function(data) {
        showFormErrors(modal, data.responseJSON.errors);
      },
      complete: function() {
        animateSpinner(modal, false);
      }
    });
  });
}

function initLoadProtocolModalPreview() {
  $('.external-import-btn').off('click').on('click', function(e) {
    var link = $(this).parents('.protocol-card');

    // When clicking on the banner button, we have no protocol-card parent
    if (link.length === 0) {
      link = $('.protocol-card.active');
    }

    animateSpinner(null, true);
    $.ajax({
      url: link.data('url'),
      type: 'GET',
      data: {
        protocol_source: link.data('protocol-source'),
        protocol_client_id: link.data('id')
      },
      dataType: 'json',
      success: function(data) {
        var modal = $('#protocol-preview-modal');
        var modalTitle = modal.find('.modal-title');
        var modalBody = modal.find('.modal-body');
        var modalFooter = modal.find('.modal-footer');

        modalTitle.html(data.title);
        modalBody.html(data.html);
        modalFooter.html(data.footer);
        initHandsOnTable(modalBody);
        modal.modal('show');
        expandAllSteps();
        initHandsOnTable(modalBody);

        if (data.validation_errors) {
          showFormErrors(modal, data.validation_errors);
        }

        initFormSubmits();
        handleFormSubmit(modal);
      },
      error: function(error) {
        console.log(error.responseJSON.errors);
        alert('Server error');
      },
      complete: function() {
        animateSpinner(null, false);
      }
    });
    e.preventDefault();
    return false;
  });
}

function initFormSubmits() {
  var modal = $('#protocol-preview-modal');
  modal.find('button[data-action=import_protocol]').off('click').on('click', function() {
    var form = modal.find('form');
    var hiddenField = form.find('#protocol_protocol_type');
    hiddenField.attr('value', $(this).data('import_type'));
    form.submit();
  });
}

applySearchCallback();
