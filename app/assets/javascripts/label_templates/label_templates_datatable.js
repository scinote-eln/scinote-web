/* global I18n DataTableHelpers HelperModule */
/* eslint-disable no-use-before-define */

(function() {
  'use strict';

  var LABEL_TEMPLATE_TABLE;
  var rowsSelected = [];

  function rowsSelectedIDs() {
    return rowsSelected.map(i => i.id);
  }

  function defaultSelected() {
    return rowsSelected.findIndex(v => v.default === 'true') >= 0;
  }

  function labelFormats() {
    let uniqueFormats = rowsSelected.map(i => i.format).filter((v, i, a) => a.indexOf(v) === i);
    if (uniqueFormats.length > 1) {
      return 'mixed';
    }
    return uniqueFormats[0];
  }

  function renderCheckboxHTML(data) {
    return `<div class="sci-checkbox-container">
              <input type="checkbox" class="sci-checkbox label-row-checkbox" data-action='toggle'
               data-label-template-id="${data}">
              <span class="sci-checkbox-label"></span>
            </div>`;
  }

  function renderDefaultTemplateHTML(data) {
    return data ? '<i class="fas fa-thumbtack"></i>' : '';
  }

  function renderNameHTML(data, type, row) {
    return `${data.icon_image_tag}<a
      href='${row.DT_RowAttr['data-edit-url']}'
      class='label-info-link'
    >${data.name}</a>`;
  }

  function addAttributesToRow(row, data) {
    $(row).addClass('label-template-row')
      .attr('data-id', data['0']);
  }

  function initToggleAllCheckboxes() {
    $('input[name="select_all"]').change(function() {
      if ($(this).is(':checked')) {
        $("[data-action='toggle']").prop('checked', true);
        $('.label-template-row').addClass('selected');
      } else {
        $("[data-action='toggle']").prop('checked', false);
        $('.label-template-row').removeClass('selected');
      }
    });
  }

  function initCreateButton() {
    $('#newLabelTemplate').on('click', function() {
      $.post(this.dataset.url);
    });
  }

  function initSetDefaultButton() {
    $('#setZplDefaultLabelTemplate, #setFluicsDefaultLabelTemplate').on('click', function() {
      if (rowsSelected.length === 1) {
        $.post(rowsSelected[0].setDefaultUrl, function(response) {
          reloadTable();
          HelperModule.flashAlertMsg(response.message, 'success');
        }).error((response) => {
          HelperModule.flashAlertMsg(response.responseJSON.error, 'danger');
        });
      }
    });
  }

  function initEditButton() {
    $('#editTemplate').on('click', function() {
      if (rowsSelected.length === 1) {
        window.location.href = rowsSelected[0].editUrl;
      }
    });
  }

  function initDuplicateButton() {
    $('#duplicateLabelTemplate').on('click', function() {
      if (rowsSelected.length > 0) {
        $.post(this.dataset.url, { selected_ids: rowsSelectedIDs() }, function(response) {
          reloadTable();
          HelperModule.flashAlertMsg(response.message, 'success');
        }).error((response) => {
          HelperModule.flashAlertMsg(response.responseJSON.error, 'danger');
        });
      }
    });
  }

  function initDeleteModal() {
    $('#deleteLabelTemplate').on('click', function() {
      $('#deleteLabelTemplatesModal').modal('show');
    });
  }

  function initDeleteButton() {
    $('#confirmLabeleDeletion').on('click', function() {
      if (rowsSelected.length > 0) {
        $.post(this.dataset.url, { selected_ids: rowsSelectedIDs() }, function(response) {
          reloadTable();
          HelperModule.flashAlertMsg(response.message, 'success');
          $('#deleteLabelTemplatesModal').modal('hide');
        }).error((response) => {
          HelperModule.flashAlertMsg(response.responseJSON.error, 'danger');
          $('#deleteLabelTemplatesModal').modal('hide');
        });
      }
    });
  }

  function initRefreshFluicsButton() {
    $('#syncFluicsTemplates').on('click', function() {
      $.post(this.dataset.url, function(response) {
        reloadTable();
        HelperModule.flashAlertMsg(response.message, 'success');
      }).error((response) => {
        HelperModule.flashAlertMsg(response.responseJSON.error, 'danger');
      });
    });
  }

  function tableDrawCallback() {
    initToggleAllCheckboxes();
    initRowSelection();
  }

  function updateButtons() {
    if (rowsSelected.length === 0) {
      $('.selected-actions').addClass('hidden');
      $('.nonselected-actions').removeClass('hidden');
      $('.fluics-warning').addClass('hidden');
    } else {
      $('.fluics-warning').addClass('hidden');
      $('.selected-actions').removeClass('hidden');
      $('.nonselected-actions').addClass('hidden');
      $('.selected-one-actions').toggleClass('hidden', (rowsSelected.length > 1));
      if (labelFormats() === 'ZPL') {
        $('#deleteLabelTemplate').toggleClass('hidden', defaultSelected());
        $('#setZplDefaultLabelTemplate').toggleClass('hidden', (rowsSelected.length > 1 || defaultSelected()));
        $('#setFluicsDefaultLabelTemplate').addClass('hidden');
      } else if (labelFormats() === 'Fluics') {
        $('#duplicateLabelTemplate').addClass('hidden');
        $('#deleteLabelTemplate').addClass('hidden');
        $('#setZplDefaultLabelTemplate').addClass('hidden');
        $('#setFluicsDefaultLabelTemplate').toggleClass('hidden', (rowsSelected.length > 1 || defaultSelected()));
        $('.fluics-warning').removeClass('hidden');
      } else {
        $('.selected-one-actions').addClass('hidden');
        $('.fluics-warning').removeClass('hidden');
        $('.selected-actions').addClass('hidden');
      }
    }
  }

  function reloadTable() {
    LABEL_TEMPLATE_TABLE.ajax.reload(null, false);
    rowsSelected = [];
    updateButtons();
  }

  function updateDataTableSelectAllCtrl() {
    var $table = LABEL_TEMPLATE_TABLE.table().node();
    var $header = LABEL_TEMPLATE_TABLE.table().header();
    var $chkboxAll = $('.label-row-checkbox', $table);
    var $chkboxChecked = $('.label-row-checkbox:checked', $table);
    var chkboxSelectAll = $('input[name="select_all"]', $header).get(0);

    // If none of the checkboxes are checked
    if ($chkboxChecked.length === 0) {
      chkboxSelectAll.checked = false;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = false;
      }

    // If all of the checkboxes are checked
    } else if ($chkboxChecked.length === $chkboxAll.length) {
      chkboxSelectAll.checked = true;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = false;
      }

    // If some of the checkboxes are checked
    } else {
      chkboxSelectAll.checked = true;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = true;
      }
    }
  }

  function initRowSelection() {
    // Handle clicks on checkbox
    $('#label-templates-table').on('change', '.label-row-checkbox', function(ev) {
      var rowId;
      var index;
      var row;

      rowId = this.dataset.labelTemplateId;
      row = $(this).closest('tr')[0];

      // Determine whether row ID is in the list of selected row IDs
      index = rowsSelected.findIndex(v => v.id === rowId);

      // If checkbox is checked and row ID is not in list of selected row IDs
      if (this.checked && index === -1) {
        rowsSelected.push({
          id: rowId,
          default: row.dataset.default,
          editUrl: row.dataset.editUrl,
          setDefaultUrl: row.dataset.setDefaultUrl,
          format: row.dataset.format
        });
      // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
      } else if (!this.checked && index !== -1) {
        rowsSelected.splice(index, 1);
      }

      if (this.checked) {
        $(this).closest('.label-template-row').addClass('selected');
      } else {
        $(this).closest('.label-template-row').removeClass('selected');
      }

      updateDataTableSelectAllCtrl();

      ev.stopPropagation();
      updateButtons();
    });
  }
  // INIT

  function initDatatable() {
    var $table = $('#label-templates-table');
    LABEL_TEMPLATE_TABLE = $table.DataTable({
      dom: "R<'label-toolbar'<'label-buttons-container'><'label-search-container'f>>t<'pagination-row hidden'<'pagination-info'li><'pagination-actions'p>>",
      order: [[2, 'desc']],
      stateSave: true,
      sScrollX: '100%',
      sScrollXInner: '100%',
      processing: true,
      serverSide: true,
      ajax: $table.data('source'),
      pagingType: 'simple_numbers',
      colReorder: {
        fixedColumnsLeft: 1000000 // Disable reordering
      },
      columnDefs: [{
        targets: 0,
        searchable: false,
        orderable: false,
        className: 'dt-body-center',
        sWidth: '1%',
        render: renderCheckboxHTML
      }, {
        targets: 1,
        searchable: false,
        orderable: true,
        sWidth: '1%',
        render: renderDefaultTemplateHTML
      }, {
        targets: 2,
        className: 'label-template-name',
        render: renderNameHTML
      }],
      oLanguage: {
        sSearch: I18n.t('general.filter')
      },
      fnDrawCallback: tableDrawCallback,
      createdRow: addAttributesToRow,
      fnInitComplete: function() {
        DataTableHelpers.initLengthAppearance($table.closest('.dataTables_wrapper'));
        DataTableHelpers.initSearchField(
          $table.closest('.dataTables_wrapper'),
          I18n.t('label_templates.index.search_templates')
        );
        $('.pagination-row').removeClass('hidden');

        let toolBar = $($('#labelTemplatesToolbar').html());
        $('.label-buttons-container').html(toolBar);
        initCreateButton();
        initEditButton();
        initSetDefaultButton();
        initDuplicateButton();
        initDeleteModal();
        initRefreshFluicsButton();
      }
    });
  }

  $('#wrapper').on('sideBar::shown sideBar::hidden', function() {
    if (LABEL_TEMPLATE_TABLE) {
      LABEL_TEMPLATE_TABLE.columns.adjust();
    }
  });

  initDatatable();
  initDeleteButton();
}());
