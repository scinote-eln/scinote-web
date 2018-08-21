//= require my_modules
//= require protocols/import_export/import
//= require comments

// Currently selected row in "load from protocol" modal
var selectedRow = null;

/**
 * Initializes page
 */
function init() {
  bindEditDueDateAjax();
  initEditDescription();
  initCopyToRepository();
  initLinkUpdate();
  initLoadFromRepository();
  initRefreshStatusBar();
  initImport();
  Comments.bindNewElement();
  Comments.initialize();
  setupAssetsLoading();
}

// Initialize edit description modal window
function initEditDescription() {
  var editDescriptionModal = $("#manage-module-description-modal");
  var editDescriptionModalBody = editDescriptionModal.find(".modal-body");
  var editDescriptionModalSubmitBtn = editDescriptionModal.find("[data-action='submit']");
  $(".description-link")
  .on("ajax:success", function(ev, data, status) {
    var descriptionLink = $(".description-refresh");

    // Set modal body & title
    editDescriptionModalBody.html(data.html);
    editDescriptionModal
    .find("#manage-module-description-modal-label")
    .text(data.title);

    editDescriptionModalBody.find("form")
    .on("ajax:success", function(ev2, data2, status2) {
      // Update module's description in the tab
      descriptionLink.html(data2.description_label);

      // Close modal
      editDescriptionModal.modal("hide");
    })
    .on("ajax:error", function(ev2, data2, status2) {
      // Display errors if needed
      $(this).renderFormErrors("my_module", data2.responseJSON);
    });

    // Show modal
    editDescriptionModal.modal("show");
  })
  .on("ajax:error", function(ev, data, status) {
    // TODO
  });

  editDescriptionModal.on("hidden.bs.modal", function() {
    editDescriptionModalBody.find("form").off("ajax:success ajax:error");
    editDescriptionModalBody.html("");
  });
}

function bindEditDueDateAjax() {
  var editDueDateModal = null;
  var editDueDateModalBody = null;
  var editDueDateModalTitle = null;
  var editDueDateModalSubmitBtn = null;

  editDueDateModal = $("#manage-module-due-date-modal");
  editDueDateModalBody = editDueDateModal.find(".modal-body");
  editDueDateModalTitle = editDueDateModal.find("#manage-module-due-date-modal-label");
  editDueDateModalSubmitBtn = editDueDateModal.find("[data-action='submit']");

  $(".due-date-link")
  .on("ajax:success", function(ev, data, status) {
    var dueDateLink = $(".task-due-date");

    // Load contents
    editDueDateModalBody.html(data.html);
    editDueDateModalTitle.text(data.title);

    // Add listener to form inside modal
    editDueDateModalBody.find("form")
    .on("ajax:success", function(ev2, data2, status2) {
      // Update module's due date
      dueDateLink.html(data2.module_header_due_date_label);

      // Close modal
      editDueDateModal.modal("hide");
    })
    .on("ajax:error", function(ev2, data2, status2) {
      // Display errors if needed
      $(this).renderFormErrors("my_module", data2.responseJSON);
    });

    // Open modal
    editDueDateModal.modal("show");
  })
  .on("ajax:error", function(ev, data, status) {
    // TODO
  });

  editDueDateModalSubmitBtn.on("click", function() {
    // Submit the form inside the modal
    editDueDateModalBody.find("form").submit();
  });

  editDueDateModal.on("hidden.bs.modal", function() {
    editDueDateModalBody.find("form").off("ajax:success ajax:error");
    editDueDateModalBody.html("");
  });
}

function initCopyToRepository() {
  var link = $("[data-action='copy-to-repository']");
  var modal = $("#copy-to-repository-modal");
  var modalBody = modal.find(".modal-body");
  var submitBtn = modal.find(".modal-footer [data-action='submit']");

  link
  .on("ajax:success", function(e, data) {
    modalBody.html(data.html);

    modalBody.find("[data-role='copy-to-repository']")
    .on("ajax:success", function(e2, data2) {
      if (data2.refresh !== null) {
        // Reload page
        location.reload();
      } else {
        // Simply hide the modal
        modal.modal("hide");
      }
    })
    .on("ajax:error", function(e2, data2) {
      // Display errors in form
      if (data2.status === 422) {
        $(this).renderFormErrors("protocol", data2.responseJSON);
      } else {
        // Simply display global error
        alert(data2.responseJSON.message);
      }
    });

    modal.modal("show");
  })
  .on("ajax:error", function() {} );

  submitBtn.on("click", function() {
    // Submit the embedded form
    modalBody.find("form").submit();
  });

  modalBody.on("click", "[data-role='link-check']", function() {
    var text = $(this).closest(".modal-body").find("[data-role='link-text']");
    if ($(this).prop("checked")) {
      text.show();
    } else {
      text.hide();
    }
  });

  modal.on("hidden.bs.modal", function() {
    modalBody.find("[data-role='copy-to-repository']")
    .off("ajax:success ajax:error");

    modalBody.html("");
  });
}

function initLinkUpdate() {
  var modal = $("#confirm-link-update-modal");
  var modalTitle = modal.find(".modal-title");
  var modalBody = modal.find(".modal-body");
  var updateBtn = modal.find(".modal-footer [data-action='submit']");
  $("[data-action='unlink'], [data-action='revert'], [data-action='update-parent'], [data-action='update-self']")
  .on("ajax:success", function(e, data) {
    modalTitle.html(data.title);
    modalBody.html(data.message);
    updateBtn.text(data.btn_text);
    modal.attr("data-url", data.url);
    modal.modal("show");
  });
  modal.on("hidden.bs.modal", function() {
    modalBody.html("");
  });

  if( !$._data( updateBtn[0], 'events' ) ) {
    updateBtn.on("click", function() {
      // POST via ajax
      $.ajax({
        url: modal.attr("data-url"),
        type: "POST",
        dataType: "json",
        success: function(ev, data) {
          // Simply reload page
          location.reload();
        },
        error: function(ev, data) {
          // Display error message in alert()
          alert(ev.responseJSON.message);

          // Hide modal
          modal.modal("hide");
        }
      });
    });
  }
}

function initLoadFromRepository() {
  var modal = $("#load-from-repository-modal");
  var modalBody = modal.find(".modal-body");
  var loadBtn = modal.find(".modal-footer [data-action='submit']");

  $("[data-action='load-from-repository']")
  .on("ajax:success", function(e, data) {
    modalBody.html(data.html);

    // Disable load btn
    loadBtn.attr("disabled", "disabled");

    modal.modal("show");

    // Init Datatable on public tab
    initLoadFromRepositoryTable(modalBody.find("#public-tab"));

    modalBody.find("a[data-toggle='tab']")
    .on("hide.bs.tab", function(e) {
      // Destroy Handsontable in to-be-hidden tab
      var content = $($(e.target).attr("href"));
      destroyLoadFromRepositoryTable(content);
    })
    .on("shown.bs.tab", function(e) {
      // Initialize Handsontable in to-be-shown tab
      var content = $($(e.target).attr("href"));
      initLoadFromRepositoryTable(content);
    });

    loadBtn.on("click", function() {
      loadFromRepository();
    });
  });
  modal.on("hidden.bs.modal", function() {
    // Destroy the current Datatable
    destroyLoadFromRepositoryTable(modalBody.find(".tab-pane.active"));

    modalBody.find("a[data-toggle='tab']")
    .off("hide.bs.tab shown.bs.tab");

    loadBtn.off("click");

    modalBody.html("");
  });
}

function initLoadFromRepositoryTable(content) {
  var tableEl = content.find("[data-role='datatable']");
  var repositoryType = tableEl.data("type");

  var datatable = tableEl.DataTable({
    order: [[1, "asc"]],
    dom: "RBfltpi",
    buttons: [],
    processing: true,
    serverSide: true,
    responsive: true,
    ajax: {
      url: tableEl.data("source"),
      type: "POST"
    },
    colReorder: {
      fixedColumnsLeft: 1000000 // Disable reordering
    },
    columnDefs: [{
      targets: 0,
      searchable: false,
      orderable: false,
      sWidth: "1%",
      render: function (data, type, full, meta) {
        return "<input type='radio'>";
      }
    }, {
      targets: [ 1, 2, 3, 4, 5, 6 ],
      searchable: true,
      orderable: true
    }],
    columns: [
      { data: "0" },
      { data: "1" },
      { data: "2" },
      { data: "3" },
      { data: "4" },
      { data: "5" },
      { data: "6" }
    ],
    oLanguage: {
      sSearch: I18n.t('general.filter')
    },
    rowCallback: function(row, data, dataIndex) {
      // Get row ID
      var rowId = data["DT_RowId"];

      $(row).attr("data-row-id", rowId);

      // If row ID is in the list of selected row IDs
      if(rowId === selectedRow){
        $(row).find("input[type='radio']").prop("checked", true);
        $(row).addClass("selected");
      }
    },
    fnDrawCallback: function(settings, json) {
      animateSpinner(this, false);
    },
    preDrawCallback: function(settings) {
      animateSpinner(this);
    }
  });

  // Handle click on table cells with radio buttons
  tableEl.find("tbody").on("click", "td", function(e) {
    $(this).parent().find("input[type='radio']").trigger("click");
  });

  // Handle clicks on radio buttons
  tableEl.find("tbody").on("click", "input[type='radio']", function(e) {
    // Get row ID
    var row = $(this).closest("tr");
    var data = datatable.row(row).data();
    var rowId = data["DT_RowId"];

    // Uncheck all radio buttons
    tableEl.find("tbody input[type='radio']")
    .prop("checked", false)
    .closest("tr")
    .removeClass("selected");

    // Select the current row
    row.find("input[type='radio']").prop("checked", true);
    selectedRow = rowId;
    row.addClass("selected");

    // Enable load btn
    content.closest(".modal")
  .find(".modal-footer [data-action='submit']")
  .removeAttr("disabled");

    e.stopPropagation();
  });

  tableEl.find("tbody").on("click", "a[data-action='filter']", function(e) {
    var link = $(this);
    var searchInput = $("#protocols-table_wrapper input[type='search']");
    var query = link.attr("data-param");

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
  tableEl.find("tbody").off("click", "a[data-action='filter']");
  tableEl.find("tbody").off("click", "input[type='radio']");
  tableEl.find("tbody").off("click", "td");

  // Destroy datatable
  tableEl.DataTable().destroy();
  tableEl.find("tbody").html("");

  selectedRow = null;

  // Disable load btn
  content.closest(".modal")
  .find(".modal-footer [data-action='submit']")
  .attr("disabled", "disabled");
}

function loadFromRepository() {
  var modal = $("#load-from-repository-modal");

  var check_linked = $("[data-role='protocol-status-bar']")
                      .text();

  var confirm_message= "";
  if( check_linked.trim() !== '(unlinked)' ){
    confirm_message = I18n.t("my_modules.protocols.load_from_repository_modal.import_to_linked_task_rep");
  } else {
    confirm_message = I18n.t("my_modules.protocols.load_from_repository_modal.confirm_message");
  }

  if (selectedRow !== null && confirm(confirm_message) ) {
    // POST via ajax
    $.ajax({
      url: modal.attr("data-url"),
      type: "POST",
      dataType: "json",
      data: { source_id: selectedRow },
      success: function(ev, data) {
        // Simply reload page
        location.reload();
      },
      error: function(ev, data) {
        // Display error message in alert()
        alert(ev.responseJSON.message);

        // Hide modal
        modal.modal("hide");
      }
    });
  }
}

function initRefreshStatusBar() {
  $("[data-role='steps-container']")
  .on(
    "ajax:success",
    function(e, data) {
      if ($(e.target).is("[data-role='edit-step-form'], [data-role='new-step-form']")) {
        // Get the status bar URL
        var url = $("[data-role='protocol-status-bar-url']").attr("data-url");

        // Fetch new updated at label
        $.ajax({
          url: url,
          type: "GET",
          dataType: "json",
          success: function (data2) {
            $("[data-role='protocol-status-bar']").html(data2.html);
            initLinkUpdate();
          }
        });
      }
    }
  );
}

function initImport() {
  var fileInput = $("[data-action='load-from-file']");

  // Make sure multiple selections of same file
  // always prompt new modal
  fileInput.find("input[type='file']").on("click", function() {
    this.value = null;
  });

  // Hack to hide "No file chosen" tooltip
  fileInput.attr("title", window.URL ? " " : "");

  fileInput.on("change", function(ev) {
    var importUrl = fileInput.attr("data-import-url");
    importProtocolFromFile(
      ev.target.files[0],
      importUrl,
      null,
      true,
      function(datas) {
        var data = datas[0];
        if (data.status === "ok") {
          // Simply reload page
          location.reload();
        } else if (data.status === 'locked') {
          alert(I18n.t("my_modules.protocols.load_from_file_error_locked"));
        } else {
          if (data.status === 'size_too_large') {
            alert(I18n.t('my_modules.protocols.load_from_file_size_error',
                         { size: $(document.body).data('file-max-size-mb') } ));
          } else {
            alert(I18n.t("my_modules.protocols.load_from_file_error"));
          }
          animateSpinner(null, false);
        }
      });

    // Clear input on self
    $(this).val("");
  });
}

init();
