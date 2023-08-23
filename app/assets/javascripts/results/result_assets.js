(function(global) {
  'use strict';

  global.ResultAssets = (function() {
    // New asset callback
    function createResultAssetCallback() {
      $('.new-result-assets-buttons')
        .on('click', '.save-result', (event) => {
          DragNDropResults.processResult(event); // eslint-disable-line no-undef
        })
        .on('click', '.cancel-new', () => {
          DragNDropResults.destroyAll(); // eslint-disable-line no-undef
        });

      $('#new-result-assets-select').on('change', '#drag-n-drop-assets', function() {
        DragNDropResults.init(this.files); // eslint-disable-line no-undef
      });
    }
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
            dragNdropAssetsInit();
            createResultAssetCallback();
          },
          error: function(xhr, status, e) {
            $(this).renderFormErrors('result', xhr.responseJSON, true, e);
            animateSpinner(null, false);
            initNewResultAsset();
          }
        });
      });
    }

    // Save asset callback
    function saveResultAssetCallback() {
      $('.edit-result-assets-buttons').on('click', '.save-result', (event) => {
        Results.processResult(event, Results.ResultTypeEnum.FILE); // eslint-disable-line no-undef
      });
    }

    function applyEditResultAssetCallback() {
      $('.edit-result-asset').off('ajax:success ajax:error').on('ajax:success', function(e, data) {
        var $result = $(this).closest('.result');
        var $form = $(data.html);
        var $prevResult = $result;
        $result.after($form);
        $prevResult.hide();

        _formAjaxResultAsset($form, $prevResult);

        // Cancel button
        $form.find('.cancel-edit').click(function () {
          $prevResult.show();
          $form.remove();
          applyEditResultAssetCallback();
          Results.toggleResultEditButtons(true);
        });

        Results.toggleResultEditButtons(false);

        $('#result_name').focus();
        saveResultAssetCallback();
      }).on('ajax:error', function(e, xhr, status, error) {
        animateSpinner(null, false);
      });
    }

    function _formAjaxResultAsset($form, $prevResult) {
      $form.on('ajax:success', function(e, data) {
        if ($prevResult) $prevResult.remove();
        $form.after(data.html);
        var $newResult = $form.next();
        initFormSubmitLinks($newResult);
        $(this).remove();
        applyEditResultAssetCallback();

        Results.toggleResultEditButtons(true);
        Results.expandResult($newResult);
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
}(window));
