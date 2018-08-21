(function() {
    'use strict';

    var ResultTables = (function() {
      // Init handsontable which can be edited
      function _initEditableHandsOnTable(root) {
        root.find('.editable-table').each(function() {
          var $container = $(this).find('.hot');
          var data = null;
          var contents = $(this).find('.hot-contents');
          if (contents.attr('value')) {
            data = JSON.parse(contents.attr('value')).data;
          }

          $container.handsontable({
            data: data,
            startRows: $('#const_data').attr('data-HANDSONTABLE_INIT_ROWS_CNT'),
            startCols: $('#const_data').attr('data-HANDSONTABLE_INIT_COLS_CNT'),
            minRows: 1,
            minCols: 1,
            rowHeaders: true,
            colHeaders: true,
            contextMenu: true,
            formulas: true,
            preventOverflow: 'horizontal'
          });
        });
      }

      function _onSubmitExtractTable($form) {
        $form.submit(function(){
          var hot = $('.hot').handsontable('getInstance');
          var contents = $('.hot-contents');
          var data = JSON.stringify({data: hot.getData()});
          contents.attr('value', data);
          return true;
        });
      }

      // Apply ajax callback to form
      function _formAjaxResultTable($form) {
        $form.on('ajax:success', function(e, data) {
          var $result;
          $form.after(data.html);
          $result = $(this).next();
          initFormSubmitLinks($result);
          $(this).remove();

          applyEditResultTableCallback();
          Results.applyCollapseLinkCallBack();
          Results.initHandsOnTables($result);
          Results.toggleResultEditButtons(true);
          Results.expandResult($result);
          Comments.initialize();
          initNewResultTable();
        });
        $form.on('ajax:error', function(e, xhr, status, error) {
          var data = xhr.responseJSON;
          $form.renderFormErrors('result', data);
        });
      }

      // Edit result table button behaviour
      function applyEditResultTableCallback() {
        $('.edit-result-table').on('ajax:success', function(e, data) {
          var $result = $(this).closest('.result');
          var $form = $(data.html);
          var $prevResult = $result;
          $result.after($form);
          $result.remove();

          _formAjaxResultTable($form);
          _initEditableHandsOnTable($form);
          _onSubmitExtractTable($form);

          // Cancel button
          $form.find('.cancel-edit').click(function () {
            $form.after($prevResult);
            $form.remove();
            applyEditResultTableCallback();
            Results.toggleResultEditButtons(true);
          });

          Results.toggleResultEditButtons(false);

          $('#result_name').focus();
        });
      }

      // New result text behaviour
      function initNewResultTable() {
        $('#new-result-table').on('click', function(event) {
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
              _formAjaxResultTable($form);
              _initEditableHandsOnTable($form);
              _onSubmitExtractTable($form);
              Results.initCancelFormButton($form, initNewResultTable);
              Results.toggleResultEditButtons(false);
              $('#result_name').focus();
            },
            error: function() {
              animateSpinner(null, false);
              initNewResultTable();
            }
          });
        });
      }

      var publicAPI = Object.freeze({
        initNewResultTable: initNewResultTable,
        applyEditResultTableCallback: applyEditResultTableCallback
      });

      return publicAPI;
    })();

    ResultTables.initNewResultTable();
    ResultTables.applyEditResultTableCallback();
})();
