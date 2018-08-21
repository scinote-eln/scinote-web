(function(global) {
  'use strict';

  var DATATABLE;
  var CHECKED_REPORTS = [];

  function tableDrowCallback() {
    checkboxToggleCallback();
    initToggleAllCheckboxes();
    updateButtons();
  }

  function initSelectPicker() {
    $('.selectpicker').selectpicker({liveSearch: true})
      .ajaxSelectPicker({
        ajax: {
          url: $('#rails_route_data').attr('data-RAILS_URL_HELPER_REPORTS_VISISBLE_PROJECTS_PATH'),
          type: 'POST',
          dataType: 'json',
          data: function () {
            return { q: '{{{q}}}' };
          }
        },
        locale: {
          emptyTitle: 'Nothing selected'
        },
        preprocessData: appendSearchResults,
        emptyRequest: true,
        clearOnEmpty: false,
        preserveSelected: false
    }).on('change.bs.select', function(el) {
      $('#new-report-reports-btn').attr('data-new-report-path', el.target.value);
    }).on('loaded.bs.select', function(el) {
      $('#new-report-reports-btn').attr('data-new-report-path', el.target.value);
    });
  }

  function appendSearchResults(data) {
    var items = [];
    if(data.hasOwnProperty('projects')){
      $.each(data.projects, function(index, el) {
        items.push(
          {
            'value': el.path,
            'text': el.name,
            'disabled': false
          }
        )
      });
    }
    return items;
  }

  function initRedirectToNewReportPage() {
    $('#new-report-reports-btn').on('click', function() {
      animateSpinner();
      var url = $(this).attr('data-new-report-path');
      $(location).attr('href', url);
    });
  }

  function initToggleAllCheckboxes() {
    $('input[name="select_all"]').change(function() {
      if($(this).is(':checked')) {
        $("[data-action='toggle']").prop('checked', true);
        addAllItems();
      } else {
        $("[data-action='toggle']").prop('checked', false);
        removeAllItems();
      }
      updateButtons();
    });
  }

  function addAllItems() {
    $.each($("[data-action='toggle']"), function(i, el) {
      CHECKED_REPORTS.push($(el).attr('data-report-id'));
    })
  }

  function removeAllItems() {
    CHECKED_REPORTS = [];
  }

  function renderCheckboxHTML(data) {
    var html;
    html = "<input data-action='toggle' data-report-id='";
    html += data + "' type='checkbox'>";
    return html;
  }

  function appendEditPathToRow(row, data) {
    $(row).addClass('report-row')
          .attr('data-edit-path', data['edit'])
          .attr('data-id', data['0']);
  }

  function checkboxToggleCallback() {
    $("[data-action='toggle']").change(function() {
      var id = $(this).attr('data-report-id');
      if($(this).is(':checked')) {
        CHECKED_REPORTS.push(id);
      } else {
        var index = CHECKED_REPORTS.indexOf(id);
        if(index != -1) {
        	CHECKED_REPORTS.splice(index, 1);
        }
      }
      updateButtons();
    });
  }

  function updateButtons() {
    var editReportButton = $('#edit-report-btn');
    var deleteReportsButton = $('#delete-reports-btn');
    if (CHECKED_REPORTS.length === 0) {
      editReportButton.addClass("disabled");
      deleteReportsButton.addClass("disabled");
    } else if (CHECKED_REPORTS.length === 1) {
      editReportButton.removeClass("disabled");
      deleteReportsButton.removeClass("disabled");
    } else {
      editReportButton.addClass("disabled");
      deleteReportsButton.removeClass("disabled");
    }
  }

  // INIT

  function initDatatable() {
    var $table = $('#reports-table')
    DATATABLE = $table.dataTable({
      'order': [[2, 'desc']],
      'processing': true,
      'serverSide': true,
      'ajax': $table.data('source'),
      'pagingType': 'simple_numbers',
      'colReorder': {
        'fixedColumnsLeft': 1000000 // Disable reordering
      },
      'columnDefs': [{
        'targets': 0,
        'searchable': false,
        'orderable': false,
        'className': 'dt-body-center',
        'sWidth': '1%',
        'render': renderCheckboxHTML
      }],
      'oLanguage': {
        'sSearch': I18n.t('general.filter')
      },
      'fnDrawCallback': tableDrowCallback,
      'createdRow': appendEditPathToRow
    });
  }

  function initEditReport() {
    $('#edit-report-btn').click(function(e) {
      e.preventDefault();
      animateSpinner();
      if (CHECKED_REPORTS.length === 1) {
        var id = CHECKED_REPORTS[0];
        var row = $(".report-row[data-id='" + id + "']");
        var url = row.attr('data-edit-path');
        $(location).attr('href', url);
      }
    });
  }

  function initDeleteReports() {
    $('#delete-reports-btn').click(function(e) {
      if (CHECKED_REPORTS.length > 0) {
         $('#report-ids').attr("value", "[" + CHECKED_REPORTS + "]");
        $('#delete-reports-modal').modal("show");
      }
    });

    $("#confirm-delete-reports-btn").click(function(e) {
      animateLoading();
    });
  }

  function initNewReportModal() {
    $('#new-report-btn').on('click', function() {
      $('#new-report-modal').modal('show');
      initSelectPicker();
      initRedirectToNewReportPage();
    });
  }

  initDatatable();
  initEditReport();
  initDeleteReports();
  initNewReportModal();
})(window);
