(function(global) {
  'use strict';

  global.ResultAssets = (function() {
    // New result asset behaviour
    function initNewResultAsset() {
      $('#new-result-asset').on('click', function(event) {
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
            _formAjaxResultAsset($form);
            Results.initCancelFormButton($form, initNewResultAsset);
            Results.toggleResultEditButtons(false);
            dragNdropAssetsInit('results');
          },
          error: function(xhr, status, e) {
            $(this).renderFormErrors('result', xhr.responseJSON, true, e);
            animateSpinner(null, false);
            initNewResultAsset();
          }
        });
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
          FilePreviewModal.init();
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
        FilePreviewModal.init();
        Comments.init();
        initNewResultAsset();
      }).on('ajax:error', function(e, xhr) {
        var errors = xhr.responseJSON.errors;
        var formInput = $form.find('#result_asset_attributes_file');
        $('[data-status="error"]').remove();
        $.each(errors, function(key, value) {
          var message = '<span data-status="error" style="color: #a94442">';
          message += value + '</span>';
          formInput.after(message);
        })
        animateSpinner(null, false);
      });
    }

    var publicAPI = Object.freeze({
      initNewResultAsset: initNewResultAsset,
      applyEditResultAssetCallback: applyEditResultAssetCallback
    });

    return publicAPI;
  })();

  ResultAssets.initNewResultAsset();
  ResultAssets.applyEditResultAssetCallback();
  FilePreviewModal.init();
}(window));
