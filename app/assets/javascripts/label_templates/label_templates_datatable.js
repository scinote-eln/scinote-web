/* global I18n DataTableHelpers */

(function() {
  'use strict';

  var LABEL_TEMPLATE_TABLE;

  function renderCheckboxHTML(data, type, row) {
    return `<div class="sci-checkbox-container">
              <input type="checkbox" class="sci-checkbox" data-action='toggle' 
               data-label-template-id="${data}" ${row.manage_permission ? '' : 'disabled'}>
              <span class="sci-checkbox-label"></span>
            </div>`;
  }

  function renderDefaultTemplateHTML(data) {
    return data ? '<i class="fas fa-thumbtack"></i>' : '';
  }

  function renderNameHTML(data, type, row) {
    return `${data.icon_url}<a href='${row.recordInfoUrl}' class='record-info-link'>${data.name}</a>`;
  }

  function addAttributesToRow(row, data) {
    $(row).addClass('label-template-row')
      .attr('data-id', data['0']);
  }

  function checkboxToggleCallback() {
    $("[data-action='toggle']").change(function() {
      if ($(this).is(':checked')) {
        $(this).closest('.label-template-row').addClass('selected');
      } else {
        $(this).closest('.label-template-row').removeClass('selected');
      }
    });
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

  function tableDrowCallback() {
    checkboxToggleCallback();
    initToggleAllCheckboxes();
  }

  // INIT

  function initDatatable() {
    var $table = $('#label-templates-table');
    LABEL_TEMPLATE_TABLE = $table.DataTable({
      dom: "Rt<'pagination-row hidden'<'pagination-info'li><'pagination-actions'p>>",
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
        $('.pagination-row').removeClass('hidden');
      }
    });
  }

  $('.label-templates-index').on('keyup', '.label-templates-search', function() {
    LABEL_TEMPLATE_TABLE.search($(this).val()).draw();
  });

  initDatatable();
}());
