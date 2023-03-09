/* global I18n DataTableHelpers animateSpinner HelperModule  Promise */

(function() {
  'use strict';

  const RETRY_COUNT = 25;
  const START_POLLING_INTERVAL = 10000;
  var CHECKED_REPORTS = [];
  var REPORTS_TABLE;

  function tableDrowCallback() {
    checkboxToggleCallback();
    initToggleAllCheckboxes();
    updateButtons();
  }

  function appendSearchResults(data) {
    var items = [];
    if (data.hasOwnProperty('projects')) {
      $.each(data.projects, function(index, el) {
        items.push(
          {
            value: el.path,
            text: el.name,
            disabled: false
          }
        )
      });
    }
    return items;
  }

  function initToggleAllCheckboxes() {
    $('input[name="select_all"]').change(function() {
      if ($(this).is(':checked')) {
        $("[data-action='toggle']").prop('checked', true);
        $('.report-row').addClass('selected');
        addAllItems();
      } else {
        $("[data-action='toggle']").prop('checked', false);
        $('.report-row').removeClass('selected');
        removeAllItems();
      }
      updateButtons();
    });
  }

  function addAllItems() {
    $.each($("[data-action='toggle']"), function(i, el) {
      CHECKED_REPORTS.push($(el).data('report-id'));
    })
  }

  function removeAllItems() {
    CHECKED_REPORTS = [];
  }

  function renderCheckboxHTML(data) {
    return `<div class="sci-checkbox-container">
              <input type="checkbox" class="sci-checkbox" data-action='toggle' data-report-id="${data}">
              <span class="sci-checkbox-label"></span>
            </div>`;
  }

  function renderDocxFile(data) {
    if (data.error) {
      let oldLink = '';
      if (data.preview_url) {
        oldLink = `<a href="#" class="file-preview-link docx" data-preview-url="${data.preview_url}">
                  (<i class="fas fa-file-docx"></i>
                  ${I18n.t('projects.reports.index.previous_docx')})
                </a>`;
      }
      return `<span class="processing-error docx">
                <i class="fas fa-exclamation-triangle"></i>
                ${I18n.t('projects.reports.index.error')}${oldLink}
              </span>`;
    }

    if (data.processing) {
      return `<span class="processing docx">
                ${I18n.t('projects.reports.index.generating')}
              </span>`;
    }

    if (data.preview_url) {
      return `<a href="#" class="file-preview-link docx" data-preview-url="${data.preview_url}">
                <i class="fas fa-file-word"></i>
                ${I18n.t('projects.reports.index.docx')}
              </a>`;
    }
    return `<a href="#" class="generate-docx docx">${I18n.t('projects.reports.index.generate')}</a>`;
  }

  function renderPdfFile(data) {
    if (data.error) {
      let oldLink = '';
      if (data.preview_url) {
        oldLink = `<a href="#" class="file-preview-link pdf" data-preview-url="${data.preview_url}">
                  (<i class="fas fa-file-pdf"></i>
                  ${I18n.t('projects.reports.index.previous_pdf')})
                </a>`;
      }
      return `<span class="processing-error pdf">
                <i class="fas fa-exclamation-triangle"></i>
                ${I18n.t('projects.reports.index.error')}${oldLink}
              </span>`;
    }

    if (data.processing) {
      return `<span class="processing pdf">
                ${I18n.t('projects.reports.index.generating')}
              </span>`;
    }

    if (data.preview_url) {
      return `<a href="#" class="file-preview-link pdf" data-preview-url="${data.preview_url}">
                <i class="fas fa-file-pdf"></i>
                ${I18n.t('projects.reports.index.pdf')}
              </a>`;
    }

    return `<a href="#" class="generate-pdf pdf">${I18n.t('projects.reports.index.generate')}</a>`;
  }

  function addAttributesToRow(row, data) {
    $(row).addClass('report-row')
      .attr('data-edit-path', data.edit)
      .attr('data-status-path', data.status)
      .attr('data-generate-pdf-path', data.generate_pdf)
      .attr('data-generate-docx-path', data.generate_docx)
      .attr('data-retry-count', 0)
      .attr('data-save-to-inventory-path', data.save_to_inventory)
      .attr('data-id', data['0']);
    if (data.archived) {
      $(row).addClass('archived');
    }
    if (data['4'].processing || data['5'].processing) {
      $(row).addClass('processing');
    }
  }

  function checkboxToggleCallback() {
    $("[data-action='toggle']").change(function() {
      var id = $(this).data('report-id');
      if ($(this).is(':checked')) {
        $(this).closest('.report-row').addClass('selected');
        CHECKED_REPORTS.push(id);
      } else {
        let index = CHECKED_REPORTS.indexOf(id);
        $(this).closest('.report-row').removeClass('selected');
        if (index !== -1) {
          CHECKED_REPORTS.splice(index, 1);
        }
      }
      updateButtons();
    });
  }

  function updateButtons() {
    if (CHECKED_REPORTS.length === 0) {
      $('.single-object-action, .multiple-object-action').addClass('disabled hidden');
    } else if (CHECKED_REPORTS.length === 1) {
      $('.single-object-action, .multiple-object-action').removeClass('disabled hidden');

      let $row = $(`.report-row[data-id=${CHECKED_REPORTS[0]}]`);
      let archived = $row.hasClass('archived');
      let pdfProcessing = $row.has('.processing.pdf').length > 0;
      let docxProcessing = $row.has('.processing.docx').length > 0;
      let docxGenerate = $row.has('.generate-docx').length > 0;

      if (pdfProcessing) {
        $('#updatePdf').addClass('disabled');
      } else {
        $('#updatePdf').removeClass('disabled');
      }

      if (docxGenerate) {
        $('#requestDocx').removeClass('hidden');
        $('#updateDocx').addClass('hidden');
      } else {
        $('#requestDocx').addClass('hidden');
        $('#updateDocx').removeClass('hidden');

        if (docxProcessing) {
          $('#updateDocx').addClass('disabled');
        } else {
          $('#updateDocx').removeClass('disabled');
        }
      }

      if (archived || pdfProcessing || docxProcessing) {
        $('#edit-report-btn').addClass('disabled');
      } else {
        $('#edit-report-btn').removeClass('disabled');
      }
    } else {
      $('.single-object-action').removeClass('hidden').addClass('disabled');
      $('.multiple-object-action').removeClass('disabled hidden');
    }
  }

  function checkProcessingStatus(reportId) {
    let $row = $('#reports-table').find(`tr[data-id="${reportId}"]`);
    if ($row.length === 0) return;

    $.getJSON($row.data('status-path'), (statusData) => {
      $row.find('.docx').parent().html(renderDocxFile(statusData.docx));
      $row.find('.pdf').parent().html(renderPdfFile(statusData.pdf));

      if (statusData.docx.processing || statusData.pdf.processing) {
        if ($row.data('retry-count') >= RETRY_COUNT) return;

        $row.data('retry-count', $row.data('retry-count') + 1);
        setTimeout(() => { checkProcessingStatus(reportId); }, START_POLLING_INTERVAL * $row.data('retry-count'));
      } else {
        $row.removeClass('processing');
      }
    });
  }

  // INIT

  function initDatatable() {
    var $table = $('#reports-table');
    REPORTS_TABLE = $table.DataTable({
      dom: "Rt<'pagination-row hidden'<'pagination-info'li><'pagination-actions'p>>",
      order: [[9, 'desc']],
      sScrollX: '100%',
      stateSave: true,
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
      },
      {
        targets: 4,
        searchable: false,
        sWidth: '60',
        render: renderPdfFile
      },
      {
        targets: 5,
        searchable: false,
        sWidth: '60',
        render: renderDocxFile
      }],
      oLanguage: {
        sSearch: I18n.t('general.filter')
      },
      fnDrawCallback: tableDrowCallback,
      createdRow: addAttributesToRow,
      fnInitComplete: function() {
        DataTableHelpers.initLengthAppearance($table.closest('.dataTables_wrapper'));
        $('.pagination-row').removeClass('hidden');
        $('.report-row.processing').each(function() {
          setTimeout(() => { checkProcessingStatus($(this).data('id')); }, START_POLLING_INTERVAL);
        });

        // add qa titles
        $('#reports-table tr').each(function() {
          var reportName = $(this).find('td:nth-child(3)').text();
          $(this).find('td:nth-child(1)').attr('title', `select report ${reportName}`);
          $(this).find('td:nth-child(3)').attr('title', `report name (${reportName})`);
          $(this).find('td:nth-child(4) a').attr('title', `report (${reportName}) pdf link`);
          $(this).find('td:nth-child(5) a').attr('title', `report (${reportName}) docx link`);
        });
      }
    });
  }

  function reloadTable() {
    REPORTS_TABLE.ajax.reload(null, false);
    removeAllItems();
    updateButtons();
  }

  function generateReportRequest(pathAttrName, id) {
    if (CHECKED_REPORTS.length === 1 || id) {
      let row = $(".report-row[data-id='" + (id || CHECKED_REPORTS[0]) + "']");
      animateSpinner();
      $.post(row.data(pathAttrName), function(response) {
        animateSpinner(null, false);
        HelperModule.flashAlertMsg(response.message, 'success');
        checkProcessingStatus(row.data('id'));
      });
    }
  }

  function initUpdatePDFReport() {
    $('#updatePdf').click(function(ev) {
      ev.stopPropagation();
      ev.preventDefault();

      new Promise(function(resolve, reject) {
        $('#regenerate-report-modal').modal('show');
        $('#regenerate-report-modal .btn-confirm').click(function() {
          resolve();
        });
        $('#regenerate-report-modal').on('hidden.bs.modal', function() {
          reject();
        });
      }).then(function() {
        $('#regenerate-report-modal').modal('hide');
        generateReportRequest('generate-pdf-path');
      }).catch(function() {});
    });
  }

  function initGenerateDocxReport() {
    $('#requestDocx').click(function(ev) {
      ev.stopPropagation();
      ev.preventDefault();
      $(this).closest('.dropdown-menu').dropdown('toggle');
      generateReportRequest('generate-docx-path');
    });
  }

  function initUpdateDocxReport() {
    $('#updateDocx').click(function(ev) {
      ev.stopPropagation();
      ev.preventDefault();

      new Promise(function(resolve, reject) {
        $('#regenerate-report-modal').modal('show');
        $('#regenerate-report-modal .btn-confirm').click(function() {
          resolve();
        });
        $('#regenerate-report-modal').on('hidden.bs.modal', function() {
          reject();
        });
      }).then(function() {
        $('#regenerate-report-modal').modal('hide');
        generateReportRequest('generate-docx-path');
      }).catch(function() {});
    });
  }

  function initEditReport() {
    $('#edit-report-btn').click(function(e) {
      e.preventDefault();
      animateSpinner();
      if (CHECKED_REPORTS.length === 1) {
        let id = CHECKED_REPORTS[0];
        let row = $(".report-row[data-id='" + id + "']");
        let url = row.attr('data-edit-path');
        $(location).attr('href', url);
      }
    });
  }

  function initSaveReportPDFToInventory() {
    $('#savePdfToInventoryButton').click(function(ev) {
      ev.preventDefault();
      ev.stopPropagation();

      let id = CHECKED_REPORTS[0];
      let row = $(`.report-row[data-id='${id}']`);
      let url = row.attr('data-save-to-inventory-path');
      $.get(url, function(result) {
        let modal = $(result.html);
        $('#content-reports-index').append(modal);
        modal.modal('show');
        // Remove modal when it gets closed
        modal.on('hidden.bs.modal', function() {
          $(this).remove();
        });
      });
    });
  }

  function initDeleteReports() {
    $('#delete-reports-btn').click(function() {
      if (CHECKED_REPORTS.length > 0) {
        $('#report-ids').attr('value', '[' + CHECKED_REPORTS + ']');
        $('#delete-reports-modal').modal('show');
      }
    });

    $('#confirm-delete-reports-btn').click(function() {
      animateLoading();
    });
  }


  $('.reports-index').on('keyup', '.report-search', function() {
    REPORTS_TABLE.search($(this).val()).draw();
  });

  $('.reports-index').on('click', '.generate-docx', function(e) {
    var reportId = $(this).closest('.report-row').attr('data-id');
    e.preventDefault();
    e.stopPropagation();
    generateReportRequest('generate-docx-path', reportId);
  });

  $('.reports-index').on('click', '.generate-pdf', function(e) {
    var reportId = $(this).closest('.report-row').attr('data-id');
    e.preventDefault();
    e.stopPropagation();
    generateReportRequest('generate-pdf-path', reportId);
  });

  $('#show_report_preview').click();

  initDatatable();
  initUpdatePDFReport();
  initGenerateDocxReport();
  initUpdateDocxReport();
  initEditReport();
  initSaveReportPDFToInventory();
  initDeleteReports();
}());
