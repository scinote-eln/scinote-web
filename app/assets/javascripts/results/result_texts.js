(function() {
  'use strict';

  var ResultText = (function() {
    // New result text behaviour
    function initNewReslutText() {
      $('#new-result-text').on('ajax:success', function(e, data) {
          var $form = $(data.html);
          $('#results').prepend($form);

          _formAjaxResultText($form);

          // Cancel button
          $form.find('.cancel-new').click(function() {
              $form.remove();
              Results.toggleResultEditButtons(true);
          });
          Results.toggleResultEditButtons(false);
          TinyMCE.refresh();
          TinyMCE.highlight();
          $('#result_name').focus();
      }).on('ajax:error', function() {
          TinyMCE.refresh();
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
            $form.find('.cancel-edit').click(function () {
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
