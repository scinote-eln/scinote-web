/* global animateSpinner PerfectSb initHandsOnTable ProtocolsIndex */
/* global HelperModule dropdownSelector protocolsIO */
/* eslint-disable no-use-before-define, no-alert */

var protocolsIO = function() {
  function applyClickCallbackOnProtocolCards() {
    $('.protocol-card').off('click').on('click', function(e) {
      var currProtocolCard = $(this);
      var baseTag = document.createElement('base');

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
            var iFrame = $('.preview-iframe');
            var scrollbox = $('.preview-holder');
            $('.preview-holder').find('.ps__rail-y').remove();
            iFrame[0].height = '0px';
            $('.empty-preview-panel').hide();
            $('.full-preview-panel').show();
            $('.full-preview-panel').attr('data-url', currProtocolCard.data('url'));
            $('.full-preview-panel').attr('data-protocol-source', currProtocolCard.data('protocol-source'));
            $('.full-preview-panel').attr('data-id', currProtocolCard.data('id'));
            $('.full-preview-panel').data('id', currProtocolCard.data('id'));
            $('.convert-protocol').attr('disabled', false);

            // Set base tag to account for relative links in the iframe
            baseTag.href = data.base_uri;
            iFrame.contents().find('head').html(baseTag);

            // Set iframe content
            iFrame.contents().find('body').html(data.html);

            scrollbox.scrollTop(0);

            iFrame.contents().find('body').find('table.htCore')
              .css('width', '100%')
              .css('table-layout', 'auto');
            iFrame.contents().find('body').find('span').css('word-break', 'break-word');
            setTimeout(() => {
              iFrame[0].height = iFrame[0].contentWindow.document.body.scrollHeight + 'px';
              iFrame.contents().find('body').bind('mousewheel', function(element, delta) {
                scrollbox.scrollTop(scrollbox.scrollTop() + (delta > 0 ? -40 : 40));
              });
              PerfectSb().update_all();
            }, 1000);

            initLoadProtocolModalPreview();
            animateSpinner($('.protocol-preview-panel'), false);
          },
          error: function() {
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

  // Handle clicks on Load more protocols button
  function applyClickCallbackOnShowMoreProtocols() {
    $('.show-more-protocols-btn button').off('click').on('click', function() {
      $('form.protocols-search-bar #page-id').val($(this).data('next-page-id'));
      $('form.protocols-search-bar').submit();
    });
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

    $('input[name="sort_by"] + label').off('click').on('click', function(e) {
      e.stopPropagation();
      $(this).prev().click();
    });


    // Bind ajax calls on the form
    $('form.protocols-search-bar').off('ajax:success').off('ajax:error')
      .on('ajax:success', function(evt, data) {
        var listWrapper = $('.list-wrapper');
        if (data.page_id > 2) {
          // Remove old load more button since we will append a new one
          $('.show-more-protocols-btn').remove();
          $('.list-wrapper').append(data.html);
        } else if (data.html) {
          resetPreviewPanel();
          $('.empty-text').hide();
          listWrapper.show().html(data.html).scrollTop(0);
        } else {
          setDefaultViewState();
        }
        PerfectSb().update_all();
        // Reset page id after every request
        $('form.protocols-search-bar #page-id').val(0);

        // Apply all callbacks on new elements
        applyClickCallbackOnProtocolCards();
        applyClickCallbackOnShowMoreProtocols();
        initLoadProtocolModalPreview();
      })
      .on('ajax:error', function() {
        setDefaultViewState();
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
      msg = errors.protocol[key].join(', ');
      if ((input.length > 0) && (errors.protocol[key].length > 0)) {
        input.closest('.form-group').children('span.help-block').html(msg);
        input.closest('.form-group').addClass('has-error');
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
  }

  function handleFormSubmit(modal) {
    var form = modal.find('form');
    form.on('submit', function(e) {
      var url = form.attr('action');
      e.preventDefault(); // avoid to execute the actual submit of the form.
      e.stopPropagation();
      animateSpinner(modal, true);

      const visibility = $('#protocol-preview-modal .modal-footer #visibility').prop('checked');
      const defaultPublicUserRoleId = $('#protocol-preview-modal .modal-footer #default_public_user_role_id')
        .prop('value');
      const visibilityField = $('#protocol-preview-modal #protocol_visibility');
      const defaultPublicUserRoleIdField = $('#protocol-preview-modal #protocol_default_public_user_role_id');

      visibilityField.prop('value', visibility ? 'visible' : 'hidden');
      defaultPublicUserRoleIdField.prop('value', defaultPublicUserRoleId);

      $.ajax({
        type: 'POST',
        url: url,
        data: form.serialize(), // serializes the form's elements.
        success: function(data) {
          animateSpinner(modal, false);
          modal.modal('hide');
          HelperModule.flashAlertMsg(data.message, 'success');
          window.protocolsTable.$refs.table.updateTable();
        },
        error: function(data) {
          showFormErrors(modal, data.responseJSON.validation_errors);
        },
        complete: function() {
          animateSpinner(modal, false);
        }
      });
    });
  }

  function initLoadProtocolModalPreview() {
    $('.convert-protocol').off('click').on('click', function(e) {
      const link = $('.full-preview-panel');
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
          $('#protocolsioModal').modal('hide');
          const modal = $('#protocol-preview-modal');
          const modalTitle = modal.find('.modal-title');
          const modalBody = modal.find('.modal-body');
          const modalFooter = modal.find('.modal-footer');

          modalTitle.text(data.title);
          modalBody.html(data.html);
          modalFooter.html(data.footer);
          initHandsOnTable(modalBody);
          modal.modal('show');
          expandAllSteps();
          initHandsOnTable(modalBody);

          if (data.validation_errors) {
            showFormErrors(modal, data.validation_errors);
          }

          initProtocolModalPreview();
          initFormSubmits();
          handleFormSubmit(modal);
        },
        error: function() {
          HelperModule.flashAlertMsg('Server error', 'danger');
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

  // Trigger initial retrieval of latest publications
  $('form.protocols-search-bar').submit();

  function initProtocolModalPreview() {
    $('#protocol-preview-modal').on('change', '#visibility', function() {
      const checkbox = this;
      $('#protocol-preview-modal #roleSelectWrapper').toggleClass('hidden', !checkbox.checked);
    });


    const roleSelector = '#protocol-preview-modal #role_selector';

    dropdownSelector.init(roleSelector, {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      onChange: function() {
        $('#protocol-preview-modal #default_public_user_role_id').val(dropdownSelector.getValues(roleSelector));
      }
    });

    $('#protocol-preview-modal')
      .on('ajax:error', 'form', function(e, error) {
        let msg = error.responseJSON.error;
        $('#protocol-preview-modal #protocol_name').parent().addClass('error').attr('data-error-text', msg);
      })
      .on('ajax:success', 'form', function(e, data) {
        if (data.message) {
          HelperModule.flashAlertMsg(data.message, 'success');
        }
        $('#protocol-preview-modal #protocol_name').parent().removeClass('error');
        $('#protocol-preview-modal').modal('hide');
      });
  }
}
