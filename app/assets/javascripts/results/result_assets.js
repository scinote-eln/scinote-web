(function(global) {
  'use strict';

  var ResutlAssets = (function() {
    // New result asset behaviour
    function initNewResultAsset() {
      $('#new-result-asset').on('ajax:success', function(e, data) {
        debugger;
        var $form = $(data.html);
        $('#results').prepend($form);

        _formAjaxResultAsset($form);

        // Cancel button
        $form.find('.cancel-new').click(function () {
          $form.remove();
          Results.toggleResultEditButtons(true);
        });

        Results.toggleResultEditButtons(false);

        $('#result_name').focus();
      }).on('ajax:error', function(e, xhr, status, error) {
        animateSpinner(null, false);
      });
    }

    function applyEditResultAssetCallback() {
      $('.edit-result-asset').on('ajax:success', function(e, data) {
        var $result = $(this).closest('.result');
        var $form = $(data.html);
        var $prevResult = $result;
        $result.after($form);
        $result.remove();

        _formAjaxResultAsset($form);

        // Cancel button
        $form.find('.cancel-edit').click(function () {
          $form.after($prevResult);
          $form.remove();
          applyEditResultAssetCallback();
          Results.toggleResultEditButtons(true);
          initPreviewModal();
        });

        Results.toggleResultEditButtons(false);

        $('#result_name').focus();
      }).on('ajax:error', function(e, xhr, status, error) {
        animateSpinner(null, false);
      });
    }

    function _formAjaxResultAsset($form) {
      $form.on('ajax:success', function(e, data) {
        $form.after(data.html);
        var $newResult = $form.next();
        initFormSubmitLinks($newResult);
        $(this).remove();
        applyEditResultAssetCallback();
        Results.applyCollapseLinkCallBack();

        Results.toggleResultEditButtons(true);
        Results.expandResult($newResult);
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

    var publicAPI = Object.freeze({
      initNewResultAsset: initNewResultAsset,
      applyEditResultAssetCallback: applyEditResultAssetCallback
    });

    return publicAPI;
  })();

  $(document).ready(function() {
    ResutlAssets.initNewResultAsset();
    ResutlAssets.applyEditResultAssetCallback();
    global.initPreviewModal();
  });
})(window);
