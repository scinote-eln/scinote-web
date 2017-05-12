(function() {
  'use strict';

  var ResultText = (function() {
    // New result text behaviour
    function initNewReslutText() {
      $('#new-result-text').on('click', function(event) {
        event.preventDefault();
        event.stopImmediatePropagation();
        event.stopPropagation();
        var $btn = $(this);
        $btn.off();
        animateSpinner(null, true);

        // get new result form
        $.ajax({
          url: $btn.data('href'),
          method: 'GET',
          success: function(data) {
            var $form = $(data.html);
            animateSpinner(null, false);
            $('#results').prepend($form);
            _formAjaxResultText($form);
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
      });
    }

    // Edit result text button behaviour
    function applyEditResultTextCallback() {
      $('.edit-result-text').on('ajax:success', function(e, data) {
        var $result = $(this).closest('.result');
        var $form = $(data.html);
        var $prevResult = $result;
        $result.after($form);
        $result.remove();

        _formAjaxResultText($form);

        // Cancel button
        $form.find('.cancel-edit').click(function() {
          $form.after($prevResult);
          $form.remove();
          applyEditResultTextCallback();
          Results.toggleResultEditButtons(true);
        });
        Results.toggleResultEditButtons(false);
        TinyMCE.refresh();
        $('#result_name').focus();
      });
    }

    // Apply ajax callback to form
    function _formAjaxResultText($form) {
      $form.on('ajax:success', function(e, data) {
        $form.after(data.html);
        var newResult = $form.next();
        initFormSubmitLinks(newResult);
        $(this).remove();

        applyEditResultTextCallback();
        Results.applyCollapseLinkCallBack();
        Results.toggleResultEditButtons(true);
        Results.expandResult(newResult);
        TinyMCE.destroyAll();
        Comments.initialize();
        initNewReslutText();
      });
      $form.on('ajax:error', function(e, xhr, status, error) {
        var data = xhr.responseJSON;
        $form.renderFormErrors('result', data);
        TinyMCE.highlight();
        if (data['result_text.text']) {
          var $el = $form.find(
            'textarea[name=result\\[result_text_attributes\\]\\[text\\]]'
          );

          $el.closest('.form-group').addClass('has-error');
          $el.parent().append('<span class=\'help-block\'>' +
            data['result_text.text'] + '</span>');
        }
      });
    }

    var publicAPI = Object.freeze({
      initNewReslutText: initNewReslutText,
      applyEditResultTextCallback: applyEditResultTextCallback
    });

    return publicAPI;
  })();

  $(document).ready(function() {
    ResultText.initNewReslutText();
    ResultText.applyEditResultTextCallback();
  });
})();
