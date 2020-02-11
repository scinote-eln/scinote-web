//= require protocols/import_export/import
/* global ProtocolRepositoryHeader */

// Global variables
var rowsSelected = [];
var protocolsTableEl = null;
var protocolsDatatable = null;
var repositoryType;

/**
 * Initializes page
 */
function init() {
  updateButtons();
  initProtocolsTable();
  initKeywordFiltering();
  initProtocolPreviewModal();
  initLinkedChildrenModal();
  initCreateNewModal();
  initModals();
  initImport();
}

// Initialize protocols DataTable
function initProtocolsTable() {
  protocolsTableEl = $("#protocols-table");
  repositoryType = protocolsTableEl.data("type");

  protocolsDatatable = protocolsTableEl.DataTable({
    order: [[1, "asc"]],
    dom: "RB<'main-actions'lf>t<'pagination-row'ip>",
    stateSave: true,
    sScrollX: '100%',
    sScrollXInner: '100%',
    buttons: [],
    processing: true,
    serverSide: true,
    ajax: {
      url: protocolsTableEl.data("source"),
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
        return "<input type='checkbox'>";
      }
    }, {
      targets: [ 1, 2, 3, 4, 5 ],
      searchable: true,
      orderable: true
    }],
    columns: [
      { data: "0" },
      { data: "1" },
      { data: "2" },
      {
        data: "3",
        visible: repositoryType != "archive"
      },
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

      // Append URLs if they exist
      if (data["DT_CanEdit"]) {
        $(row).attr("data-can-edit", "true");
        $(row).attr("data-edit-url", data["DT_EditUrl"]);
      }
      if (data["DT_CanClone"]) {
        $(row).attr("data-can-clone", "true");
        $(row).attr("data-clone-url", data["DT_CloneUrl"]);
      }
      if (data["DT_CanMakePrivate"]) { $(row).attr("data-can-make-private", "true"); }
      if (data["DT_CanPublish"]) { $(row).attr("data-can-publish", "true"); }
      if (data["DT_CanArchive"]) { $(row).attr("data-can-archive", "true"); }
      if (data["DT_CanRestore"]) { $(row).attr("data-can-restore", "true"); }
      if (data["DT_CanExport"]) { $(row).attr("data-can-export", "true"); }

      // If row ID is in the list of selected row IDs
      if($.inArray(rowId, rowsSelected) !== -1){
        $(row).find("input[type='checkbox']").prop("checked", true);
        $(row).addClass("selected");
      }
    },
    fnDrawCallback: function(settings, json) {
      animateSpinner(this, false);
      initRowSelection();
      $.initTooltips();
    },
    preDrawCallback: function(settings) {
      animateSpinner(this);
    },
    stateSaveCallback: function (settings, data) {
      // Set a cookie with the table state using the team id
      localStorage.setItem(
        "datatables_protocols_state/" +
        protocolsTableEl.data("team-id") +
        "/" + repositoryType,
        JSON.stringify(data)
      );
    },
    stateLoadCallback: function (settings) {
      // Load the table state for the current team
      var state = localStorage.getItem(
        "datatables_protocols_state/" +
        protocolsTableEl.data("team-id") +
        "/" + repositoryType
      );
      if (state !== null) {
        return JSON.parse(state);
      }
      return null;
    }
  });
}

function initRowSelection() {
  let protocolsTableScrollHead = protocolsTableEl.closest('.dataTables_scroll').find('.dataTables_scrollHead');

  // Handle click on table cells with checkboxes
  protocolsTableEl.on("click", "tbody td, thead th:first-child", function(e) {
    $(this).parent().find("input[type='checkbox']").trigger("click");
  });

  // Handle clicks on checkbox
  protocolsTableEl.find("tbody").on("click", "input[type='checkbox']", function(e) {
    // Get row ID
    var row = $(this).closest("tr");
    var data = protocolsDatatable.row(row).data();
    var rowId = data["DT_RowId"];

    // Determine whether row ID is in the list of selected row IDs
    var index = $.inArray(rowId, rowsSelected);

    // If checkbox is checked and row ID is not in list of selected row IDs
    if (this.checked && index === -1) {
      rowsSelected.push(rowId);
      // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
    } else if (!this.checked && index !== -1) {
      rowsSelected.splice(index, 1);
    }

    if (this.checked) {
      row.addClass("selected");
    } else {
      row.removeClass("selected");
    }

    updateDataTableSelectAllCheckbox();
    e.stopPropagation();
    updateButtons();
  });

  // Handle click on "Select all" control
  protocolsTableScrollHead.find("thead input[name='select_all']").on('click', function(e) {
    if (this.checked) {
      protocolsTableEl.find("tbody input[type='checkbox']:not(:checked)").trigger('click');
    } else {
      protocolsTableEl.find("tbody input[type='checkbox']:checked").trigger('click');
    }

    // Prevent click event from propagating to parent
    e.stopPropagation();
  });
}

function initKeywordFiltering() {
  protocolsTableEl.find("tbody").on("click", "a[data-action='filter']", function(e) {
    var link = $(this);
    var searchInput = $("#protocols-table_wrapper input[type='search']");
    var query = link.attr("data-param");

    // Re-search data
    protocolsDatatable.search(query).draw();

    // Don't propagate this further up
    e.stopPropagation();
    return false;
  });
}

function initProtocolPreviewModal() {
  // Only do this if the repository is public/private
  if (repositoryType !== "archive") {
    // If you are in protocol repository
    var protocolsEl = protocolsTableEl;
    // If you are in search results
    if (document.getElementById("search-content")) {
      protocolsEl = $("#search-content");
    }
    protocolsEl.on("click", "a[data-action='protocol-preview']", function(e) {
      var link = $(this);
      $.ajax({
        url: link.attr("data-url"),
        type: "GET",
        dataType: "json",
        success: function (data) {
          var modal = $("#protocol-preview-modal");
          var modalTitle = modal.find(".modal-title");
          var modalBody = modal.find(".modal-body");
          var modalFooter = modal.find(".modal-footer");
          modalTitle.html(data.title);
          modalBody.html(data.html);
          modalFooter.html(data.footer);
          initHandsOnTable(modalBody);
          modal.modal("show");
          ProtocolRepositoryHeader.init();
          initHandsOnTable(modalBody);
          FilePreviewModal.init({ readOnly: true });
        },
        error: function (error) {
          // TODO
        }
      });
      e.preventDefault();
      return false;
    });
  }
}

function initLinkedChildrenModal() {
  // Only do this if the repository is public/private
  if (repositoryType !== "archive") {
    protocolsTableEl.on("click", "a[data-action='load-linked-children']", function(e) {
      var link = $(this);
      $.ajax({
        url: link.attr("data-url"),
        type: "GET",
        dataType: "json",
        success: function (data) {
          var modal = $("#linked-children-modal");
          var modalTitle = modal.find(".modal-title");
          var modalBody = modal.find(".modal-body");
          modalTitle.html(data.title);
          modalBody.html(data.html);
          modal.modal("show");

          childrenTableEl = modalBody.find("#linked-children-table");

          if (childrenTableEl) {
            // Only initialize table if it's present
            var childrenDatatable = childrenTableEl.DataTable({
              autoWidth: false,
              dom: "RBltpi",
              stateSave: false,
              buttons: [],
              processing: true,
              serverSide: true,
              ajax: {
                url: childrenTableEl.data("source"),
                type: "POST"
              },
              colReorder: {
                fixedColumnsLeft: 1000000 // Disable reordering
              },
              columnDefs: [{
                targets: 0,
                searchable: false,
                orderable: false
              }],
              columns: [
                { data: "1" }
              ],
              fnDrawCallback: function(settings, json) {
                animateSpinner(this, false);
              },
              preDrawCallback: function(settings) {
                animateSpinner(this);
              }
            });
          }
        },
        error: function (error) {
          // TODO
        }
      });

      e.preventDefault();
      return false;
    });
  }
}

function initCreateNewModal() {
  var link = $("[data-action='create-new']");
  var modal = $("#create-new-modal");
  var submitBtn = modal.find(".modal-footer [data-action='submit']");

  link.on("click", function() {
    $.ajax({
      url: link.attr("data-url"),
      type: "GET",
      dataType: "json",
      success: function (data) {
        var modalBody = modal.find(".modal-body");
        modalBody.html(data.html);

        modalBody.find("form")
        .on("ajax:success", function(ev2, data2, status2) {
          // Redirect to edit page
          $(location).attr("href", data2.url);
        })
        .on("ajax:error", function(ev2, data2, status2) {
          // Display errors if needed
          $(this).renderFormErrors("protocol", data2.responseJSON);
        });

        modal.modal("show");
        modalBody.find("input[type='text']").focus();
      },
      error: function (error) {
        // TODO
      }
    });
  });

  submitBtn.on("click", function() {
    // Submit the form inside modal
    $(this).closest(".modal").find(".modal-body form").submit();
  });

  modal.on("hidden.bs.modal", function(e) {
    modal.find(".modal-body form").off("ajax:success ajax:error");
    modal.find(".modal-body").html("");
  });
}

function initModals() {
  function refresh(modal) {
    modal.find(".modal-body").html("");

    // Simply re-render table
    protocolsDatatable.ajax.reload();
  }

  // Make private modal hidden action
  $("#make-private-results-modal").on("hidden.bs.modal", function(e) {
    refresh($(this));
    updateDataTableSelectAllCheckbox();
    updateButtons();
  });

  // Publish modal hidden action
  $("#publish-results-modal").on("hidden.bs.modal", function(e) {
    refresh($(this));
    updateDataTableSelectAllCheckbox();
    updateButtons();
  });

  // Confirm archive modal hidden action
  $("#confirm-archive-modal").on("hidden.bs.modal", function(e) {
    // Unbind from click event on the submit button
    $(this).find(".modal-footer [data-action='submit']")
    .off("click");
  })

  // Archive modal hidden action
  $("#archive-results-modal").on("hidden.bs.modal", function(e) {
    refresh($(this));
    updateDataTableSelectAllCheckbox();
    updateButtons();
  });

  // Restore modal hidden action
  $("#restore-results-modal").on("hidden.bs.modal", function(e) {
    refresh($(this));
    updateDataTableSelectAllCheckbox();
    updateButtons();
  });

  // Linked children modal close action
  $("#linked-children-modal").on("hidden.bs.modal", function(e) {
    $(this).find(".modal-title").html("");
    // Destroy the embedded data table
    $(this).find(".modal-body #linked-children-table").DataTable().destroy();
    $(this).find(".modal-body").html("");
  });

  // Protocol preview modal close action
  $("#protocol-preview-modal").on("hidden.bs.modal", function(e) {
    $(this).find(".modal-title").html("");
    $(this).find(".modal-body").html("");
    $(this).find(".modal-footer").html("");
  });
}

function updateDataTableSelectAllCheckbox() {
  var table = protocolsDatatable.table().node();
  var checkboxesAll = $("tbody input[type='checkbox']", protocolsTableEl);
  var checkboxesChecked = $("tbody input[type='checkbox']:checked", protocolsTableEl);
  var checkboxSelectAll = $("thead input[name='select_all']", table).get(0);

  if (checkboxesChecked.length === 0) {
    // If none of the checkboxes are checked
    checkboxSelectAll.checked = false;
    if("indeterminate" in checkboxSelectAll) {
      checkboxSelectAll.indeterminate = false;
    }
  } else if (checkboxesChecked.length === checkboxesAll.length) {
    // If all of the checkboxes are checked
    checkboxSelectAll.checked = true;
    if ("indeterminate" in checkboxSelectAll) {
      checkboxSelectAll.indeterminate = false;
    }
  } else {
    // If some of the checkboxes are checked
    checkboxSelectAll.checked = true;
    if ("indeterminate" in checkboxSelectAll) {
      checkboxSelectAll.indeterminate = true;
    }
  }
}

function updateButtons() {
  var editBtn = $("[data-action='edit']");
  var cloneBtn = $("[data-action='clone']");
  var makePrivateBtn = $("[data-action='make-private']");
  var publishBtn = $("[data-action='publish']");
  var archiveBtn = $("[data-action='archive']");
  var restoreBtn = $("[data-action='restore']");
  var exportBtn = $("[data-action='export']");

  if (rowsSelected.length == 1) {
    // 1 ROW SELECTED
    var row = $("tr[data-row-id='" + rowsSelected[0] + "']");

    if (row.is("[data-can-edit]")) {
      editBtn.removeAttr("disabled");
      editBtn.off("click").on("click", function() { editSelectedProtocol(); });
    } else {
      editBtn.attr("disabled", "disabled");
      editBtn.off("click");
    }
    if (row.is("[data-can-clone]")) {
      cloneBtn.removeAttr("disabled");
      cloneBtn.off("click").on("click", function() { cloneSelectedProtocol(); });
    } else {
      cloneBtn.attr("disabled", "disabled");
      cloneBtn.off("click");
    }
    if (row.is("[data-can-make-private]")) {
      makePrivateBtn.removeAttr("disabled");
      makePrivateBtn.off("click").on("click", function() { processMoveButtonClick($(this)); });
    } else {
      makePrivateBtn.attr("disabled", "disabled");
      makePrivateBtn.off("click");
    }
    if (row.is("[data-can-publish]")) {
      publishBtn.removeAttr("disabled");
      publishBtn.off("click").on("click", function() { processMoveButtonClick($(this)); });
    } else {
      publishBtn.attr("disabled", "disabled");
      publishBtn.off("click");
    }
    if (row.is("[data-can-archive]")) {
      archiveBtn.removeAttr("disabled");
      archiveBtn.off("click").on("click", function() { processMoveButtonClick($(this)); });
    } else {
      archiveBtn.attr("disabled", "disabled");
      archiveBtn.off("click");
    }
    if (row.is("[data-can-restore]")) {
      restoreBtn.removeAttr("disabled");
      restoreBtn.off("click").on("click", function() { processMoveButtonClick($(this)); });
    } else {
      restoreBtn.attr("disabled", "disabled");
      restoreBtn.off("click");
    }
    if (row.is("[data-can-export]")) {
      exportBtn.removeAttr("disabled");
      exportBtn.off("click").on("click", function() { exportProtocols(rowsSelected); });
    } else {
      exportBtn.attr("disabled", "disabled");
      exportBtn.off("click");
    }
  } else if (rowsSelected.length === 0) {
    // 0 ROWS SELECTED
    editBtn.attr("disabled", "disabled");
    editBtn.off("click");
    cloneBtn.attr("disabled", "disabled");
    cloneBtn.off("click");
    makePrivateBtn.attr("disabled", "disabled");
    makePrivateBtn.off("click");
    publishBtn.attr("disabled", "disabled");
    publishBtn.off("click");
    archiveBtn.attr("disabled", "disabled");
    archiveBtn.off("click");
    restoreBtn.attr("disabled", "disabled");
    restoreBtn.off("click");
    exportBtn.attr("disabled", "disabled");
    exportBtn.off("click");
  } else {
    // > 1 ROWS SELECTED
    var rows = [];
    _.each(rowsSelected, function(rowId) {
      rows.push($("tr[data-row-id='" + rowId + "']")[0]);
    });
    rows = $(rows);

    // Only enable button if all selected rows can
    // be published/archived/restored/exported
    editBtn.attr("disabled", "disabled");
    editBtn.off("click");
    cloneBtn.attr("disabled", "disabled");
    cloneBtn.off("click");
    if (!rows.is(":not([data-can-make-private])")) {
      makePrivateBtn.removeAttr("disabled");
      makePrivateBtn.off("click").on("click", function() { processMoveButtonClick($(this)); });
    } else {
      makePrivateBtn.attr("disabled", "disabled");
      makePrivateBtn.off("click");
    }
    if (!rows.is(":not([data-can-publish])")) {
      publishBtn.removeAttr("disabled");
      publishBtn.off("click").on("click", function() { processMoveButtonClick($(this)); });
    } else {
      publishBtn.attr("disabled", "disabled");
      publishBtn.off("click");
    }
    if (!rows.is(":not([data-can-archive])")) {
      archiveBtn.removeAttr("disabled");
      archiveBtn.off("click").on("click", function() { processMoveButtonClick($(this)); });
    } else {
      archiveBtn.attr("disabled", "disabled");
      archiveBtn.off("click");
    }
    if (!rows.is(":not([data-can-restore])")) {
      restoreBtn.removeAttr("disabled");
      restoreBtn.off("click").on("click", function() { processMoveButtonClick($(this)); });
    } else {
      restoreBtn.attr("disabled", "disabled");
      restoreBtn.off("click");
    }
    if (!rows.is(":not([data-can-export])")) {
      exportBtn.removeAttr("disabled");
      exportBtn.off("click").on("click", function() { exportProtocols(rowsSelected); });
    } else {
      exportBtn.attr("disabled", "disabled");
      exportBtn.off("click");
    }
  }
}

function exportProtocols(ids) {
  if (ids.length > 0) {
    var params = '?protocol_ids[]=' + ids[0];
    for (var i = 1; i < ids.length; i++) {
      params += '&protocol_ids[]=' + ids[i];
    }
    params = encodeURI(params);
    window.location.href = $("[data-action='export']")
                             .data('export-url') + params;
  }
}

function editSelectedProtocol() {
  if (rowsSelected.length && rowsSelected.length == 1) {
    var row = $("tr[data-row-id='" + rowsSelected[0] + "']");

    // Redirect to edit page
    $(location).attr("href", row.attr("data-edit-url"));
  }
}

function cloneSelectedProtocol() {
  if (rowsSelected.length && rowsSelected.length == 1) {
    var row = $("tr[data-row-id='" + rowsSelected[0] + "']");

    animateSpinner();
    $.ajax({
      url: row.attr("data-clone-url"),
      type: "POST",
      dataType: "json",
      success: function (data) {
        animateSpinner(null, false);
        // Reload page
        location.reload();
      },
      error: function (error) {
        animateSpinner(null, false);
        // Reload page
        location.reload();
      }
    });
  }
}

function processMoveButtonClick(btn) {
  var action = btn.attr("data-action");
  var url = btn.attr("data-url");

  if (action === "archive") {
    confirmModal = $("#confirm-archive-modal");

    confirmModal
    .find(".modal-footer [data-action='submit']")
    .on("click", function(e) {
      confirmModal.modal("hide");
      moveSelectedProtocols(action, url);
    });

    // Show the modal
    confirmModal.modal("show");
  } else {
    moveSelectedProtocols(action, url);
  }
}

function moveSelectedProtocols(action, url) {
  animateSpinner();
  $.ajax({
    url: url,
    type: "POST",
    dataType: "json",
    data: { protocol_ids: rowsSelected },
    success: function (data) {
      rowsSelected = [];

      // Display the modal
      var modal = $("#" + action + "-results-modal");
      var modalBody = modal.find(".modal-body");
      modalBody.html(data.html);
      animateSpinner(null, false);
      modal.modal("show");
    },
    error: function (error) {
      animateSpinner(null, false);
      if (error.status == 401) {
        // Unauthorized
        alert(I18n.t("protocols.index." + action.replace("-", "_") + "_unauthorized"));
      } else {
        // Generic error
        alert(I18n.t("protocols.index." + action.replace("-", "_") + "_error"));
      }
    }
  });
}

function initImport() {
  // Some templating code duplication. I know, I hate myself
  function newElement(name, values) {
    var template = $("[data-template='" + name + "']").clone();
    template.removeAttr("data-template");
    template.show();

    // Populate values in the template
    if (values !== null) {
      _.each(values, function(val, key) {
        template.find("[data-val='" + key + "']").html(val);
      });
    }

    return template;
  }

  function addChildToElement(parentEl, name, childEl) {
    parentEl.find("[data-hold='" + name + "']").append(childEl);
  }

  var importResultsModal = $("#import-results-modal");
  var fileInput = $("[data-role='import-file-input']");

  // Make sure multiple selections of same file
  // always prompt new modal
  fileInput.find("input[type='file']").on("click", function() {
    this.value = null;
  });

  // Hack to hide "No file chosen" tooltip
  fileInput.attr("title", window.webkitURL ? " " : "");

  fileInput.on("change", function(ev) {
    var importUrl = fileInput.attr("data-import-url");
    var teamId = fileInput.attr("data-team-id");
    var type = fileInput.attr("data-type");
    importProtocolFromFile(
      ev.target.files[0],
      importUrl,
      { team_id: teamId, type: type },
      false,
      function(datas) {
        var nrSuccessful = 0;
        var failed = [];
        var unchanged = [];
        var renamed = [];
        _.each(datas, function(data) {
          if (data.status === "ok") {
            nrSuccessful++;

            if (data.name === data.new_name) {
              unchanged.push(data);
            } else {
              renamed.push(data);
            }
          } else {
            failed.push(data);
          }
        });

        // Display the results modal by cloning
        // templates and populating them
        var modalBody = importResultsModal.find(".modal-body");
        if (failed.length > 0) {
          var failedMessageEl = newElement(
            "import-result-message-error",
            {
              message: I18n.t("protocols.index.import_results.message_failed", { nr: failed.length })
            }
          );
          modalBody.append(failedMessageEl);
          animateSpinner(null, false);
        }
        if (nrSuccessful > 0) {
          var successMessageEl = newElement(
            "import-result-message-success",
            {
              message: I18n.t("protocols.index.import_results.message_ok", { nr: nrSuccessful })
            }
          );
          modalBody.append(successMessageEl);
        }
        var resultsListEl = newElement("import-result-list");
        modalBody.append(resultsListEl);
        if (unchanged.length > 0) {
          _.each(unchanged, function(pr) {
            var itemEl = newElement(
              "import-result-unchanged-item",
              { message: pr.name }
            );
            addChildToElement(resultsListEl, "items", itemEl);
          });
        }
        if (renamed.length > 0) {
          _.each(renamed, function(pr) {
            var itemEl = newElement(
              "import-result-renamed-item",
              { message: I18n.t("protocols.index.row_renamed_html", { old_name: pr.name, new_name: pr.new_name }) }
            );
            addChildToElement(resultsListEl, "items", itemEl);
          });
        }
        if (failed.length > 0) {
          _.each(failed, function(pr) {
            var itemEl = newElement(
              "import-result-failed-item",
              {
                message: pr.name,
                message2: (pr.status === "size_too_large" ? I18n.t("protocols.index.import_results.row_file_too_large") : "")
              }
            );
            addChildToElement(resultsListEl, "items", itemEl);
          });
        }

        importResultsModal.modal("show");
      }
    );
    $(this).val("");
  });
  importResultsModal.on("hidden.bs.modal", function() {
    importResultsModal.find(".modal-body").html("");

    // Also reload table
    protocolsDatatable.ajax.reload();
  });
}

init();
