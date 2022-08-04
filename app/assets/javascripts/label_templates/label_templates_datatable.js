/* global I18n DataTableHelpers HelperModule */
/* eslint-disable no-use-before-define */

(function() {
  'use strict';

  var LABEL_TEMPLATE_TABLE;
  var rowsSelected = [];
  var defaultSelected = false;
  var editUrl;
  var setDefaultUrl;

  function renderCheckboxHTML(data, type, row) {
    return `<div class="sci-checkbox-container">
              <input type="checkbox" class="sci-checkbox label-row-checkbox" data-action='toggle'
               data-label-template-id="${data}" ${row.manage_permission ? '' : 'disabled'}>
              <span class="sci-checkbox-label"></span>
            </div>`;
  }

  function renderDefaultTemplateHTML(data) {
    return data ? '<i class="fas fa-thumbtack"></i>' : '';
  }

  function renderNameHTML(data, type, row) {
    return `${data.icon_url}<a
      href='${row.DT_RowAttr['data-edit-url']}'
      class='record-info-link'
      onclick='window.open(this.href, "_self")'
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
    $('#setDefaultLabelTemplate').on('click', function() {
      if (rowsSelected.length === 1) {
        $.post(setDefaultUrl, function(response) {
          reloadTable();
          HelperModule.flashAlertMsg(response.message, 'success');
        }).error((response) => {
          HelperModule.flashAlertMsg(response.responseJSON.error, 'danger');
        });
      }
    });
  }

  function initDuplicateButton() {
    $('#duplicateLabelTemplate').on('click', function() {
      if (rowsSelected.length > 0) {
        $.post(this.dataset.url, { selected_ids: rowsSelected }, function(response) {
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
        $.post(this.dataset.url, { selected_ids: rowsSelected }, function(response) {
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

  function tableDrowCallback() {
    initToggleAllCheckboxes();
    initRowSelection();
  }

  function updateButtons() {
    if (rowsSelected.length === 0) {
      $('.selected-actions').addClass('hidden');
    } else {
      $('.selected-actions').removeClass('hidden');
      $('#editLabelTemplate').attr('disabled', rowsSelected.length > 1);
      $('#deleteLabelTemplate').attr('disabled', defaultSelected);
      $('#setDefaultLabelTemplate').attr('disabled', (rowsSelected.length > 1 || defaultSelected));
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

  function checkDefaultSelection() {
    $.each($('.label-template-row .fa-thumbtack'), function(i, defaultLabel) {
      let rowId = ($(defaultLabel).closest('.label-template-row').data('id')).toString();
      let index = $.inArray(rowId, rowsSelected);
      if (index >= 0) {
        defaultSelected = true;
        return;
      }
      defaultSelected = false;
    });
  }

  function initRowSelection() {
    // Handle clicks on checkbox
    $('#label-templates-table').on('change', '.label-row-checkbox', function(ev) {
      var rowId;
      var index;

      rowId = this.dataset.labelTemplateId;

      // Determine whether row ID is in the list of selected row IDs
      index = $.inArray(rowId, rowsSelected);

      // If checkbox is checked and row ID is not in list of selected row IDs
      if (this.checked && index === -1) {
        rowsSelected.push(rowId);
      // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
      } else if (!this.checked && index !== -1) {
        rowsSelected.splice(index, 1);
      }

      if (this.checked) {
        $(this).closest('.label-template-row').addClass('selected');
      } else {
        $(this).closest('.label-template-row').removeClass('selected');
      }

      if (rowsSelected.length === 1) {
        editUrl = $(`.label-template-row[data-id="${rowsSelected[0]}"]`).data('edit-url');
        setDefaultUrl = $(`.label-template-row[data-id="${rowsSelected[0]}"]`).data('set-default-url');
      }


      updateDataTableSelectAllCtrl();
      checkDefaultSelection();

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
        orderable: false,
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
      fnDrawCallback: tableDrowCallback,
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
        initSetDefaultButton();
        initDuplicateButton();
        initDeleteModal();
      }
    });
  }

  initDatatable();
  initDeleteButton();
}());
