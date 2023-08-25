/* eslint-disable no-unused-vars */
/*
 global Results ActiveStorage animateSpinner Comments ResultAssets FilePreviewModal
        TinyMCE getParam applyCreateWopiFileCallback initFormSubmitLinks textValidator
        GLOBAL_CONSTANTS ActiveStoragePreviews
*/

(function(global) {
  'use strict';

  global.Results = (function() {
    var ResultTypeEnum = Object.freeze({
      FILE: 0,
      TABLE: 1,
      TEXT: 2
    });

    function initHandsOnTables(root) {
      root.find('div.hot-table').each(function() {
        var $container = $(this).find('.step-result-hot-table');
        var contents = $(this).find('.hot-contents');
        var metadata = $(this).find('.hot-metadata');
        $container.handsontable({
          width: '100%',
          startRows: 5,
          startCols: 5,
          rowHeaders: true,
          colHeaders: true,
          fillHandle: false,
          formulas: true,
          data: JSON.parse(contents.attr('value')).data,
          cell: (metadata.val() || {}).cells || [],
          readOnly: true
        });
        let hot = $container.handsontable('getInstance');
        setTimeout(() => {
          hot.render();
        }, 500);
      });
    }

    // Toggle editing buttons
    function toggleResultEditButtons(show) {
      if (show) {
        $('#results-toolbar').show();
        $('.edit-result-button').show();
      } else {
        $('.edit-result-button').hide();
        $('#results-toolbar').hide();
      }
    }

    function renderTable(table) {
      $(table).handsontable('render');
      // Yet another dirty hack to solve HandsOnTable problems
      if (parseInt($(table).css('height'), 10) < parseInt($(table).css('max-height'), 10) - 30) {
        $(table).find('.ht_master .wtHolder').css({ height: '100%', width: '100%' });
      }
    }

    // Expand all results
    function expandAllResults() {
      $('.result .panel-collapse').collapse('show');
      $(document).find('div.step-result-hot-table').each(function() {
        renderTable(this);
      });
    }

    function expandResult(result) {
      $('.panel-collapse', result).collapse('show');
      renderTable($(result).find('div.step-result-hot-table'));
      animateSpinner(null, false);
    }

    // create custom ajax request in order to fix issuses with remote: true from
    function handleResultFileSubmit(form, ev) {
      if (!(form.find('#result_asset_attributes_file')[0].files.length > 0)) {
        // Assuming that only result name is getting updated
        return;
      }

      ev.preventDefault();
      ev.stopPropagation();

      const url = form.find('#result_asset_attributes_file').data('directUploadUrl');
      const file = form.find('#result_asset_attributes_file')[0].files[0];
      const upload = new ActiveStorage.DirectUpload(file, url);

      animateSpinner();

      upload.create((error, blob) => {
        if (error) {
          // Handle the error
        } else {
          let formData = new FormData();
          const assetId = form.find('#result_asset_attributes_id').val();
          formData.append('result[name]', form.find('#result_name').val());
          formData.append('result[asset_attributes][id]', assetId);
          formData.append('result[asset_attributes][signed_blob_id]', blob.signed_id);

          $.ajax({
            type: 'PUT',
            url: form.attr('action'),
            data: formData,
            success: function(data) {
              animateSpinner(null, false);
              $('.edit-result-asset').parent().remove();
              $(data.html).prependTo('#results').promise().done(() => {
                $.each($('#results').find('.result'), function() {
                  initFormSubmitLinks($(this));
                  ResultAssets.applyEditResultAssetCallback();
                  applyCreateWopiFileCallback();
                  toggleResultEditButtons(true);
                  Comments.init();
                  ResultAssets.initNewResultAsset();
                  expandResult($(this));
                });
                ActiveStoragePreviews.reloadPreview(`.asset[data-asset-id=${assetId}] .attachment-preview img`);
              });

              $('#results-toolbar').show();
            },
            error: function(XHR) {
              animateSpinner(null, false);
              $('.edit-result-asset').renderFormErrors('result', XHR.responseJSON.errors);
            },
            processData: false,
            contentType: false
          });
        }
      });
    }

    function processResult(ev, resultTypeEnum) {
      var textWithoutImages;
      var $form = $(ev.target.form);
      $form.clearFormErrors();

      textValidator(ev, $form.find('#result_name'), 0, GLOBAL_CONSTANTS.NAME_MAX_LENGTH);

      switch (resultTypeEnum) {
        case ResultTypeEnum.FILE:
          handleResultFileSubmit($form, ev);
          break;
        case ResultTypeEnum.TABLE:
          $form
            .find(`.${GLOBAL_CONSTANTS.HAS_UNSAVED_DATA_CLASS_NAME}`)
            .removeClass(GLOBAL_CONSTANTS.HAS_UNSAVED_DATA_CLASS_NAME);
          break;
        case ResultTypeEnum.TEXT:
          textWithoutImages = TinyMCE.getContent().replaceAll(/src="(data:image\/[^;]+;base64[^"]+)"/g, '');

          textValidator(
            ev, $form.find('#result_text_attributes_textarea'), 1,
            $form.data('rich-text-max-length'), false, textWithoutImages
          );
          break;
        default:
          // do nothing
      }
    }

    // init cancel button
    function initCancelFormButton(form, callback) {
      $(form).find('.cancel-new').click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        $(form).remove();
        toggleResultEditButtons(true);
        TinyMCE.destroyAll();
        callback();
      });
    }

    function archive(e, element) {
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();
      let el = $(element);
      if (confirm(el.data('confirm-text'))) {
        animateSpinner();
        $('#' + el.data('form-id')).submit();
      }
    }

    function initArchive() {
      $('#results').on('click', '.form-submit-link', function(event) {
        archive(event, this);
      });
    }

    function init() {
      initHandsOnTables($(document));
      expandAllResults();
      applyCreateWopiFileCallback();

      $(function() {
        $('#results-collapse-btn').click(function() {
          $('.result .panel-collapse').collapse('hide');
        });

        $('#results-expand-btn').click(expandAllResults);
      });

      // This checks if the ctarget param exist in the rendered url and opens the
      // comment tab
      if (getParam('ctarget')) {
        let target = '#' + getParam('ctarget');
        $(target).find('a.comment-tab-link').click();
      }

      initArchive();
    }

    let publicAPI = Object.freeze({
      init: init,
      initHandsOnTables: initHandsOnTables,
      toggleResultEditButtons: toggleResultEditButtons,
      expandResult: expandResult,
      processResult: processResult,
      ResultTypeEnum: ResultTypeEnum,
      initCancelFormButton: initCancelFormButton,
      archive: archive
    });

    return publicAPI;
  }());

  Results.init();
}(window));
