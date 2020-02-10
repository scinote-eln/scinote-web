/*
 global Results ActiveStorage animateSpinner Comments ResultAssets FilePreviewModal
        TinyMCE getParam applyCreateWopiFileCallback initFormSubmitLinks textValidator
        GLOBAL_CONSTANTS
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

        $container.handsontable({
          width: '100%',
          startRows: 5,
          startCols: 5,
          rowHeaders: true,
          colHeaders: true,
          fillHandle: false,
          formulas: true,
          cells: function(row, col) {
            var cellProperties = {};

            if (col >= 0) {
              cellProperties.readOnly = true;
            } else {
              cellProperties.readOnly = false;
            }
            return cellProperties;
          }
        });
        let hot = $container.handsontable('getInstance');
        let data = JSON.parse(contents.attr('value'));
        if (Array.isArray(data.data)) hot.loadData(data.data);
        setTimeout(() => {
          hot.render()
        }, 0)
      });
    }

    function applyCollapseLinkCallBack() {
      $('.result-panel-collapse-link')
        .on('ajax:success', function() {
          var collapseIcon = $(this).find('.collapse-result-icon');
          var collapsed = $(this).hasClass('collapsed');
          // Toggle collapse button
          collapseIcon.toggleClass('fa-caret-square-up', !collapsed);
          collapseIcon.toggleClass('fa-caret-square-down', collapsed);
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
      $(document).find('span.collapse-result-icon').each(function() {
        $(this).addClass('fa-caret-square-up');
        $(this).removeClass('fa-caret-square-down');
      });
      $(document).find('div.step-result-hot-table').each(function() {
        renderTable(this);
      });
    }

    function expandResult(result) {
      $('.panel-collapse', result).collapse('show');
      $(result).find('span.collapse-result-icon').each(function() {
        $(this).addClass('fa-caret-square-up');
        $(this).removeClass('fa-caret-square-down');
      });
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
          formData.append('result[name]', form.find('#result_name').val());
          formData.append('result[asset_attributes][id]', form.find('#result_asset_attributes_id').val());
          formData.append('result[asset_attributes][signed_blob_id]', blob.signed_id);

          $.ajax({
            type: 'PUT',
            url: form.attr('action'),
            data: formData,
            success: function(data) {
              animateSpinner(null, false);
              $('.edit_result').parent().remove();
              $(data.html).prependTo('#results').promise().done(() => {
                $.each($('#results').find('.result'), function() {
                  initFormSubmitLinks($(this));
                  ResultAssets.applyEditResultAssetCallback();
                  applyCollapseLinkCallBack();
                  applyCreateWopiFileCallback();
                  toggleResultEditButtons(true);
                  FilePreviewModal.init();
                  Comments.init();
                  ResultAssets.initNewResultAsset();
                  expandResult($(this));
                });
              });

              $('#results-toolbar').show();
            },
            error: function(XHR) {
              animateSpinner(null, false);
              $('.edit_result').renderFormErrors('result', XHR.responseJSON.errors);
            },
            processData: false,
            contentType: false
          });
        }
      });
    }

    function processResult(ev, resultTypeEnum) {
      var $form = $(ev.target.form);
      $form.clearFormErrors();

      textValidator(ev, $form.find('#result_name'), 0, GLOBAL_CONSTANTS.NAME_MAX_LENGTH);

      switch (resultTypeEnum) {
        case ResultTypeEnum.FILE:
          handleResultFileSubmit($form, ev);
          break;
        case ResultTypeEnum.TABLE:
          break;
        case ResultTypeEnum.TEXT:
          textValidator(
            ev, $form.find('#result_text_attributes_textarea'), 1,
            $form.data('rich-text-max-length'), false, TinyMCE.getContent()
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

    function init() {
      initHandsOnTables($(document));
      expandAllResults();
      applyCollapseLinkCallBack();
      applyCreateWopiFileCallback();

      $(function() {
        $('#results-collapse-btn').click(function() {
          $('.result .panel-collapse').collapse('hide');
          $(document).find('span.collapse-result-icon')
            .addClass('fa-caret-square-down')
            .removeClass('fa-caret-square-up');
        });

        $('#results-expand-btn').click(expandAllResults);
      });

      // This checks if the ctarget param exist in the rendered url and opens the
      // comment tab
      if (getParam('ctarget')) {
        let target = '#' + getParam('ctarget');
        $(target).find('a.comment-tab-link').click();
      }
    }

    let publicAPI = Object.freeze({
      init: init,
      initHandsOnTables: initHandsOnTables,
      applyCollapseLinkCallBack: applyCollapseLinkCallBack,
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
