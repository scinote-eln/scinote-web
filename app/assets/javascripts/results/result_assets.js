(function(global) {
  'use strict';

  var ResutlAssetHandler = (function() {
    var self = this;
    var publicAPI = Object.freeze({
      initNewResultAsset: function initNewResultAsset() {
        // New result asset behaviour
        $('#new-result-asset').on('ajax:success', function(e, data) {
          var $form = $(data.html);
          $('#results').prepend($form);
          debugger;
          self.formAjaxResultAsset($form);

          // Cancel button
          $form.find('.cancel-new').click(function () {
            $form.remove();
            toggleResultEditButtons(true);
          });

          toggleResultEditButtons(false);

          $('#result_name').focus();
        });

        $('#new-result-asset')
          .on('ajax:error', function(e, xhr, status, error) {
          animateSpinner(null, false);
        });
      },
      applyEditResultAssetCallback: function applyEditResultAssetCallback() {
        $('.edit-result-asset').on('ajax:success', function(e, data) {
          var $result = $(this).closest('.result');
          var $form = $(data.html);
          var $prevResult = $result;
          $result.after($form);
          $result.remove();

          formAjaxResultAsset($form);

          // Cancel button
          $form.find('.cancel-edit').click(function () {
            $form.after($prevResult);
            $form.remove();
            applyEditResultAssetCallback();
            toggleResultEditButtons(true);
            initPreviewModal();
          });

          toggleResultEditButtons(false);

          $('#result_name').focus();
        });

        $('.edit-result-asset')
          .on('ajax:error', function(e, xhr, status, error) {
          animateSpinner(null, false);
        });
      },
      formAjaxResultAsset: function formAjaxResultAsset($form) {
        $form.on('ajax:success', function(e, data) {
          $form.after(data.html);
          var $newResult = $form.next();
          initFormSubmitLinks($newResult);
          $(this).remove();
          applyEditResultAssetCallback();
          Results.applyCollapseLinkCallBack();

          toggleResultEditButtons(true);
          expandResult($newResult);
          initPreviewModal();
          Comments.initialize();
        }).on('ajax:error', function(e, data) {
          // This check is here only because of remotipart bug, which returns
          // HTML instead of JSON, go figure
          var errors = '';
          if (data.errors)
            errors = data.errors;
          else
            errors = data.responseJSON.errors;
          $form.renderFormErrors('result', errors, true, e);
          animateSpinner(null, false);
        });
      }
    });

    return publicAPI;
  })();

  ResutlAssetHandler.initNewResultAsset();
  ResutlAssetHandler.applyEditResultAssetCallback();
  global.initPreviewModal();
})(window);
