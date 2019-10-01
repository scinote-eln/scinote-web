/* global TinyMCE I18n animateSpinner importProtocolFromFile truncateLongString */
/* global HelperModule GLOBAL_CONSTANTS */
/* eslint-disable no-use-before-define, no-alert, no-restricted-globals, no-underscore-dangle */

//= require my_modules
//= require protocols/import_export/import

// Currently selected row in "load from protocol" modal
var selectedRow = null;


function initEditMyModuleDescription() {
  $('#my_module_description_view').on('click', function() {
    TinyMCE.init('#my_module_description_textarea');
  });
}

function initEditProtocolDescription() {
  $('#protocol_description_view').on('click', function() {
    TinyMCE.init('#protocol_description_textarea', refreshProtocolStatusBar);
  });
}

// Initialize edit description modal window
function initEditDescription() {
  var editDescriptionModal = $('#manage-module-description-modal');
  var editDescriptionModalBody = editDescriptionModal.find('.modal-body');
  $('.description-link')
    .on('ajax:success', function(ev, data) {
      var descriptionLink = $('.description-refresh');

      // Set modal body & title
      editDescriptionModalBody.html(data.html);
      editDescriptionModal
        .find('#manage-module-description-modal-label')
        .text(data.title);

      editDescriptionModalBody.find('form')
        .on('ajax:success', function(ev2, data2) {
          // Update module's description in the tab
          descriptionLink.html(data2.description_label);

          // Close modal
          editDescriptionModal.modal('hide');
        })
        .on('ajax:error', function(ev2, data2) {
          // Display errors if needed
          $(this).renderFormErrors('my_module', data2.responseJSON);
        });

      // Show modal
      editDescriptionModal.modal('show');
    });


  editDescriptionModal.on('hidden.bs.modal', function() {
    editDescriptionModalBody.find('form').off('ajax:success ajax:error');
    editDescriptionModalBody.html('');
  });
}

function initCopyToRepository() {
  var link = $("[data-action='copy-to-repository']");
  var modal = $('#copy-to-repository-modal');
  var modalBody = modal.find('.modal-body');
  var submitBtn = modal.find(".modal-footer [data-action='submit']");

  link
    .on('ajax:success', function(e, data) {
      modalBody.html(data.html);

      modalBody.find("[data-role='copy-to-repository']")
        .on('ajax:success', function(e2, data2) {
          if (data2.refresh !== null) {
            // Reload page
            location.reload();
          } else {
            // Simply hide the modal
            modal.modal('hide');
          }
        })
        .on('ajax:error', function(e2, data2) {
          // Display errors in form
          submitBtn[0].disabled = false;
          if (data2.status === 422) {
            $(this).renderFormErrors('protocol', data2.responseJSON);
          } else {
            // Simply display global error
            alert(data2.responseJSON.message);
          }
        });

      modal.modal('show');
      submitBtn[0].disabled = false;
    })
    .on('ajax:error', function() {});

  submitBtn.on('click', function() {
    // Submit the embedded form
    submitBtn[0].disabled = true;
    modalBody.find('form').submit();
  });

  modalBody.on('click', "[data-role='link-check']", function() {
    var text = $(this).closest('.modal-body').find("[data-role='link-text']");
    if ($(this).prop('checked')) {
      text.show();
    } else {
      text.hide();
    }
  });

  modal.on('hidden.bs.modal', function() {
    modalBody.find("[data-role='copy-to-repository']")
      .off('ajax:success ajax:error');

    modalBody.html('');
  });
}

function initLinkUpdate() {
  var modal = $('#confirm-link-update-modal');
  var modalTitle = modal.find('.modal-title');
  var modalBody = modal.find('.modal-body');
  var updateBtn = modal.find(".modal-footer [data-action='submit']");
  $("[data-action='unlink'], [data-action='revert'], [data-action='update-parent'], [data-action='update-self']")
    .on('ajax:success', function(e, data) {
      modalTitle.html(data.title);
      modalBody.html(data.message);
      updateBtn.text(data.btn_text);
      modal.attr('data-url', data.url);
      modal.modal('show');
    });
  modal.on('hidden.bs.modal', function() {
    modalBody.html('');
  });

  if (!$._data(updateBtn[0], 'events')) {
    updateBtn.on('click', function() {
      // POST via ajax
      $.ajax({
        url: modal.attr('data-url'),
        type: 'POST',
        dataType: 'json',
        success: function() {
          // Simply reload page
          location.reload();
        },
        error: function(ev) {
          // Display error message in alert()
          alert(ev.responseJSON.message);

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

      // Init Datatable on public tab
      initLoadFromRepositoryTable(modalBody.find('#public-tab'));

      modalBody.find("a[data-toggle='tab']")
        .on('hide.bs.tab', function(el) {
          // Destroy Handsontable in to-be-hidden tab
          var content = $($(el.target).attr('href'));
          destroyLoadFromRepositoryTable(content);
        })
        .on('shown.bs.tab', function(el) {
          // Initialize Handsontable in to-be-shown tab
          var content = $($(el.target).attr('href'));
          initLoadFromRepositoryTable(content);
        });

      loadBtn.on('click', function() {
        loadFromRepository();
      });
    });
  modal.on('hidden.bs.modal', function() {
    // Destroy the current Datatable
    destroyLoadFromRepositoryTable(modalBody.find('.tab-pane.active'));

    modalBody.find("a[data-toggle='tab']")
      .off('hide.bs.tab shown.bs.tab');

    loadBtn.off('click');

    modalBody.html('');
  });
}

function initLoadFromRepositoryTable(content) {
  var tableEl = content.find("[data-role='datatable']");

  var datatable = tableEl.DataTable({
    order: [[1, 'asc']],
    dom: "RBfl<'row'<'col-sm-12't>><'row'<'col-sm-7'i><'col-sm-5'p>>",
    sScrollX: '100%',
    sScrollXInner: '100%',
    buttons: [],
    processing: true,
    serverSide: true,
    responsive: true,
    ajax: {
      url: tableEl.data('source'),
      type: 'POST'
    },
    colReorder: {
      fixedColumnsLeft: 1000000 // Disable reordering
    },
    columnDefs: [{
      targets: 0,
      searchable: false,
      orderable: false,
      sWidth: '1%',
      render: function() {
        return "<input type='radio'>";
      }
    }, {
      targets: [1, 2, 3, 4, 5, 6],
      searchable: true,
      orderable: true
    }],
    columns: [
      { data: '0' },
      { data: '1' },
      { data: '2' },
      { data: '3' },
      { data: '4' },
      { data: '5' },
      { data: '6' }
    ],
    oLanguage: {
      sSearch: I18n.t('general.filter')
    },
    rowCallback: function(row, data) {
      // Get row ID
      var rowId = data.DT_RowId;

      $(row).attr('data-row-id', rowId);

      // If row ID is in the list of selected row IDs
      if (rowId === selectedRow) {
        $(row).find("input[type='radio']").prop('checked', true);
        $(row).addClass('selected');
      }
    },
    fnDrawCallback: function() {
      animateSpinner(this, false);
    },
    preDrawCallback: function() {
      animateSpinner(this);
    }
  });

  // Handle click on table cells with radio buttons
  tableEl.find('tbody').on('click', 'td', function() {
    $(this).parent().find("input[type='radio']").trigger('click');
  });

  // Handle clicks on radio buttons
  tableEl.find('tbody').on('click', "input[type='radio']", function(e) {
    // Get row ID
    var row = $(this).closest('tr');
    var data = datatable.row(row).data();
    var rowId = data.DT_RowId;

    // Uncheck all radio buttons
    tableEl.find("tbody input[type='radio']")
      .prop('checked', false)
      .closest('tr')
      .removeClass('selected');

    // Select the current row
    row.find("input[type='radio']").prop('checked', true);
    selectedRow = rowId;
    row.addClass('selected');

    // Enable load btn
    content.closest('.modal')
      .find(".modal-footer [data-action='submit']")
      .removeAttr('disabled');

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
  tableEl.find('tbody').off('click', "input[type='radio']");
  tableEl.find('tbody').off('click', 'td');

  // Destroy datatable
  tableEl.DataTable().destroy();
  tableEl.find('tbody').html('');

  selectedRow = null;

  // Disable load btn
  content.closest('.modal')
    .find(".modal-footer [data-action='submit']")
    .attr('disabled', 'disabled');
}

function loadFromRepository() {
  var modal = $('#load-from-repository-modal');

  var checkLinked = $("[data-role='protocol-status-bar']")
    .text();

  var confirmMessage = '';
  if (checkLinked.trim() !== '(unlinked)') {
    confirmMessage = I18n.t('my_modules.protocols.load_from_repository_modal.import_to_linked_task_rep');
  } else {
    confirmMessage = I18n.t('my_modules.protocols.load_from_repository_modal.confirm_message');
  }

  if (selectedRow !== null && confirm(confirmMessage)) {
    // POST via ajax
    $.ajax({
      url: modal.attr('data-url'),
      type: 'POST',
      dataType: 'json',
      data: { source_id: selectedRow },
      success: function() {
        // Simply reload page
        location.reload();
      },
      error: function(ev) {
        // Display error message in alert()
        alert(ev.responseJSON.message);

        // Hide modal
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
      $("[data-role='protocol-status-bar']").html(data.html);
      initLinkUpdate();
    }
  });
}

function initImport() {
  var fileInput = $("[data-action='load-from-file']");

  // Make sure multiple selections of same file
  // always prompt new modal
  fileInput.find("input[type='file']").on('click', function() {
    this.value = null;
  });

  // Hack to hide "No file chosen" tooltip
  fileInput.attr('title', window.URL ? ' ' : '');

  fileInput.on('change', function(ev) {
    var importUrl = fileInput.attr('data-import-url');
    importProtocolFromFile(
      ev.target.files[0],
      importUrl,
      null,
      true,
      function(datas) {
        var data = datas[0];
        if (data.status === 'ok') {
          // Simply reload page
          location.reload();
        } else if (data.status === 'locked') {
          alert(I18n.t('my_modules.protocols.load_from_file_error_locked'));
        } else {
          if (data.status === 'size_too_large') {
            alert(I18n.t('my_modules.protocols.load_from_file_size_error',
              { size: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB }));
          } else {
            alert(I18n.t('my_modules.protocols.load_from_file_error'));
          }
          animateSpinner(null, false);
        }
      }
    );
    // Clear input on self
    $(this).val('');
  });
}

function initRecentProtocols() {
  var recentProtocolContainer = $('.my-module-recent-protocols');
  var dropDownList = recentProtocolContainer.find('.dropdown-menu');
  recentProtocolContainer.find('.dropdown-button').click(function() {
    dropDownList.find('.protocol').remove();
    $.get('/protocols/recent_protocols', result => {
      $.each(result, (i, protocol) => {
        $('<div class="protocol"><i class="fas fa-file-alt"></i>'
          + truncateLongString(protocol.name, GLOBAL_CONSTANTS.NAME_TRUNCATION_LENGTH)
          + '</div>').appendTo(dropDownList)
          .click(() => {
            $.post(recentProtocolContainer.data('updateUrl'), { source_id: protocol.id })
              .success(() => {
                location.reload();
              })
              .error(ev => {
                HelperModule.flashAlertMsg(ev.responseJSON.message, 'warning');
              });
          });
      });
    });
  });

  $('.protocol-description-content').on('ajax:success', () => {
    updateRecentProtocolsStatus();
  });
}

function updateRecentProtocolsStatus() {
  var recentProtocolContainer = $('.my-module-recent-protocols');
  var steps = $('.step');
  var protocolDescription = $('#protocol_description_view').html();
  if (steps.length === 0 && protocolDescription.length === 0) {
    recentProtocolContainer.css('display', '');
  } else {
    recentProtocolContainer.css('display', 'none');
  }
}

/**
 * Initializes page
 */
function init() {
  initEditMyModuleDescription();
  initEditProtocolDescription();
  initEditDescription();
  initCopyToRepository();
  initLinkUpdate();
  initLoadFromRepository();
  refreshProtocolStatusBar();
  initImport();
  initRecentProtocols();
}

init();
