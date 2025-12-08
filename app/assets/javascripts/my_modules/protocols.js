/* global TinyMCE Prism I18n animateSpinner importProtocolFromFile */
/* global HelperModule DataTableHelpers $ */
/* eslint-disable no-use-before-define, no-alert, no-restricted-globals, no-underscore-dangle */


//= require protocols/import_export/import

// Currently selected row in "load from protocol" modal
var selectedRow = null;


function initLinkUpdate() {
  var modal = $('#confirm-link-update-modal');
  var modalTitle = modal.find('.modal-title');
  var modalMessage = modal.find('.modal-body .message');
  var modalMergeLabel = modal.find('.modal-body .merge-label');
  var modalReplaceLabel = modal.find('.modal-body .replace-label');
  var updateBtn = modal.find(".modal-footer [data-action='submit']");
  $('.protocol-options-dropdown')
    .on('ajax:success', "[data-action='unlink'], [data-action='update-parent']", function(e, data) {
      modal.find(".modal-body .load-options-container").hide();
      modalTitle.text(data.title);
      modalMessage.html(data.message);
      updateBtn.text(data.btn_text);
      modal.attr('data-url', data.url);
      modal.modal('show');

    });

  $('.protocol-options-dropdown')
    .on('ajax:success', "[data-action='revert'], [data-action='update-self']", function(e, data) {
      modal.find(".modal-body .load-options-container").show();
      modalTitle.text(data.title);
      modalMessage.html(data.message);
      modalMergeLabel.html(data.merge_text);
      modalReplaceLabel.html(data.replace_text);
      updateBtn.text(data.btn_text);
      modal.find("input[name='load_option'][value='merge']").prop("checked", true)
      modal.attr('data-url', data.url);
      modal.modal('show');

    });

  modal.on('hidden.bs.modal', function() {
    modalMessage.html('');
  });

  if (!$._data(updateBtn[0], 'events')) {
    updateBtn.on('click', function() {
      let selectedOption = modal.find("input[name='load_option']:checked").val();
      modal.find(".modal-footer [data-action='submit']").prop('disabled', true);

      // POST via ajax
      $.ajax({
        url: modal.attr('data-url'),
        type: 'POST',
        dataType: 'json',
        data: { load_mode: selectedOption },
        success: function() {
          // Simply reload page
          location.reload();
        },
        error: function(ev) {
          // Display error message in alert()
          alert(ev.responseJSON.message);
          modal.find(".modal-footer [data-action='submit']").prop('disabled', false);
          // Hide modal
          modal.modal('hide');
        }
      });
    });
  }

  $('[data-role="protocol-status-bar"] .preview-protocol').click(function(e) {
    e.preventDefault();
  });
}

function initLoadFromRepository() {
  var modal = $('#load-from-repository-modal');
  var modalBody = modal.find('.modal-body');
  var loadBtn = modal.find(".modal-footer [data-action='submit']");

  $("[data-action='load-from-repository']")
    .on('ajax:success', function(e, data) {
      modalBody.html(data.html);

      // Disable load btn
      loadBtn.attr('disabled', 'disabled');

      modal.modal('show');

      // Init Datatable on recent tab
      initLoadFromRepositoryTable(modalBody.find('#load-protocols-datatable'));

      loadBtn.on('click', function() {
        let isEmpty = $('#my_module_is_empty').val() === 'true';
        if (!isEmpty) {
          // Show warning modal
          loadFromRepositoryWarning();
          return;
        }

        $("#load-from-repository-warning-modal input[name='load_option'][value=replace]").prop('checked', true);
        modal.modal('hide');
        loadFromRepository();

      });
    });
  modal.on('hidden.bs.modal', function() {
    // Destroy the current Datatable
    destroyLoadFromRepositoryTable(modalBody.find('#load-protocols-datatable'));
    loadBtn.off('click');
    modalBody.html('');
  });
}

function initLoadFromRepositoryTable(content) {
  var tableEl = content.find("[data-role='datatable']");
  var datatable = tableEl.DataTable({
    dom: "R<'main-actions'<'toolbar'><'protocol-filters'f>>t"
      + "<'pagination-row'<'pagination-info'li><'pagination-actions'p>>",
    sScrollX: '100%',
    sScrollXInner: '100%',
    buttons: [],
    processing: true,
    serverSide: true,
    responsive: true,
    order: [[5, 'desc']],
    ajax: {
      url: tableEl.data('source'),
      type: 'POST'
    },
    colReorder: {
      fixedColumnsLeft: 1000000 // Disable reordering
    },
    columnDefs: [{
      targets: [0, 3, 4],
      searchable: true,
      orderable: true
    }, {
      targets: [1, 2, 5],
      searchable: true,
      orderable: true,
      render: function(data) {
        return `<div class="nowrap">${data}</div`;
      }
    }],
    columns: [
      { data: '0' },
      { data: '1' },
      { data: '2' },
      { data: '3' },
      { data: '4' },
      { data: '5' }
    ],
    oLanguage: {
      sSearch: I18n.t('general.filter')
    },
    rowCallback: function(row, data) {
      // Get row ID
      var rowId = data.DT_RowId;
      $(row).attr('data-row-id', rowId);
    },
    fnDrawCallback: function() {
      animateSpinner(this, false);
    },
    preDrawCallback: function() {
      animateSpinner(this);
    },
    fnInitComplete: function(e) {
      var dataTableWrapper = $(e.nTableWrapper);
      DataTableHelpers.initLengthAppearance(dataTableWrapper);
      $('#my_module_is_empty').val(e.json.my_module_is_empty ? 'true' : 'false');
      DataTableHelpers.initSearchField(
        dataTableWrapper,
        I18n.t('my_modules.protocols.load_from_repository_modal.filter_protocols')
      );

      $('.toolbar').html(I18n.t('my_modules.protocols.load_from_repository_modal.text2'));
    }
  });

  // Handle clicks on row
  tableEl.find('tbody').on('click', 'tr', function(e) {
    // Uncheck all
    tableEl.find('tbody tr.selected').removeClass('selected');

    // Select the current row
    selectedRow = datatable.row($(this)).data().DT_RowId;
    $(this).addClass('selected');

    // Enable load btn
    content.closest('.modal')
      .find(".modal-footer [data-action='submit']")
      .attr('disabled', false);

    e.stopPropagation();
  });

  tableEl.find('tbody').on('click', "a[data-action='filter']", function(e) {
    var link = $(this);
    var query = link.attr('data-param');

    // Re-search data
    datatable.search(query).draw();

    // Don't propagate this further up
    e.stopPropagation();
    return false;
  });
}

function destroyLoadFromRepositoryTable(content) {
  var tableEl = content.find("[data-role='datatable']");

  // Unbind event listeners
  tableEl.find('tbody').off('click', "a[data-action='filter']");
  tableEl.find('tbody').off('click', 'tr');

  // Destroy datatable
  tableEl.DataTable().destroy();
  tableEl.find('tbody').html('');

  // Disable load btn
  content.closest('.modal')
    .find(".modal-footer [data-action='submit']")
    .attr('disabled', 'disabled');
}

function loadFromRepositoryWarning() {
  var modal = $('#load-from-repository-warning-modal');
  var loadBtn = modal.find(".modal-footer [data-action='submit']");


  modal.modal('show');
  $('#load-from-repository-modal').modal('hide');

  loadBtn.on('click', function() {
    loadFromRepository();
  });

  modal.on('hidden.bs.modal', function() {
    loadBtn.off('click');
  });
}

function loadFromRepository() {
  var modal = $('#load-from-repository-warning-modal');

  if (selectedRow !== null) {
    modal.find(".modal-footer [data-action='submit']").prop('disabled', true);
    let loadMode = $("#load-from-repository-warning-modal input[name='load_option']:checked").val();
    // POST via ajax
    $.ajax({
      url: modal.attr('data-url'),
      type: 'POST',
      dataType: 'json',
      data: {
        source_id: selectedRow,
        load_mode: loadMode
      },
      success: function() {
        // Simply reload page
        location.reload();
      },
      error: function(response) {
        if (response.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
        } else {
          alert(response.responseJSON.message);
        }

        modal.find(".modal-footer [data-action='submit']").prop('disabled', false);
        selectedRow = null;
        modal.modal('hide');
      }
    });
  }
}

function refreshProtocolStatusBar() {
  // Get the status bar URL
  var url = $("[data-role='protocol-status-bar-url']").attr('data-url');

  // Fetch new updated at label
  $.ajax({
    url: url,
    type: 'GET',
    dataType: 'json',
    success: function(data) {
      $('.my-module-protocol-status').replaceWith(data.html);
      initLinkUpdate();
    }
  });
}

function initDetailsDropdown() {
  $('#task-details .task-section-caret').on('click', function() {
    if (!$('.task-details').hasClass('collapsing')) {
      $(this).closest('#task-details').toggleClass('expanded');
    }
  });
}

function initProtocolSectionOpenEvent() {
  $('#protocol-container').on('shown.bs.collapse', function() {
    $(this).find("[data-role='hot-table']").each(function() {
      var $container = $(this).find("[data-role='step-hot-table']");
      var hot = $container.handsontable('getInstance');
      hot.render();
    });
  });
}

/**
 * Initializes page
 */
function init() {
  initLinkUpdate();
  initLoadFromRepository();
  initProtocolSectionOpenEvent();
  initDetailsDropdown();
}

init();
