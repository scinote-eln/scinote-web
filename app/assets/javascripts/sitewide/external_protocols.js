/* global animateSpinner initHandsOnTable */
/* eslint-disable no-restricted-globals, no-alert */

var ExternalProtocols = (function() {
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
    var externalProtocols = $('.external-protocol-result');
    externalProtocols.on('click', 'a[data-action="external-import"]', function(e) {
      var link = $(this);
      animateSpinner(null, true);
      $.ajax({
        url: link.attr('data-url'),
        type: 'GET',
        data: {
          protocol_source: link.attr('data-source'),
          protocol_client_id: link.attr('data-id')
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
    modal.on('click', 'button[data-action=import_protocol]', function() {
      var form = modal.find('form');
      var hiddenField = form.find('#protocol_protocol_type');
      hiddenField.attr('value', $(this).data('import_type'));
      form.submit();
    });
  }

  return {
    init: () => {
      if ($('.external-protocols-tab').length > 0) {
        initLoadProtocolModalPreview();
        initFormSubmits();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  ExternalProtocols.init();
});
