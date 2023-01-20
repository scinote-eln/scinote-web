//= require protocols/import_export/import
/* eslint-disable no-use-before-define, no-underscore-dangle, max-len */
/* global ProtocolRepositoryHeader PdfPreview DataTableHelpers importProtocolFromFile _
          dropdownSelector filterDropdown I18n animateSpinner initHandsOnTable */

// Global variables
(function() {
  var PERMISSIONS = ['archivable', 'restorable', 'copyable'];
  var rowsSelected = [];
  var protocolsTableEl = null;
  var protocolsDatatable = null;
  var repositoryType;


  var publishedOnFromFilter;
  var publishedOnToFilter;
  var modifiedOnFromFilter;
  var modifiedOnToFilter;
  var publishedByFilter;
  var accessByFilter;
  var hasDraftFilter;
  var archivedOnFromFilter;
  var archivedOnToFilter;
  var protocolsViewSearch;


  /**
   * Initializes page
   */
  function init() {
    updateButtons();
    initProtocolsTable();
    initKeywordFiltering();
    initProtocolPreviewModal();
    initLinkedChildrenModal();
    initModals();
    initImport();
    initVersionsModal();
  }

  function selectDate($field) {
    var datePicker = $field.data('DateTimePicker');
    if (datePicker && datePicker.date()) {
      return datePicker.date()._d.toUTCString();
    }
    return null;
  }

  function initProtocolsFilters() {
    var $filterDropdown = filterDropdown.init();
    let $protocolsFilter = $('.protocols-index .protocols-filters');
    let $publishedByFilter = $('.published-by-filter', $protocolsFilter);
    let $accessByFilter = $('.access-by-filter', $protocolsFilter);
    let $hasDraft = $('#has_draft', $protocolsFilter);
    let $publishedOnFromFilter = $('.published-on-filter .from-date', $protocolsFilter);
    let $publishedOnToFilter = $('.published-on-filter .to-date', $protocolsFilter);
    let $modifiedOnFromFilter = $('.modified-on-filter .from-date', $protocolsFilter);
    let $modifiedOnToFilter = $('.modified-on-filter .to-date', $protocolsFilter);
    let $archivedOnFromFilter = $('.archived-on-filter .from-date', $protocolsFilter);
    let $archivedOnToFilter = $('.archived-on-filter .to-date', $protocolsFilter);
    let $textFilter = $('#textSearchFilterInput', $protocolsFilter);

    function appliedFiltersMark() {
      let filtersEnabled = protocolsViewSearch
        || publishedOnFromFilter
        || publishedOnToFilter
        || modifiedOnFromFilter
        || modifiedOnToFilter
        || (publishedByFilter && publishedByFilter.length !== 0)
        || (accessByFilter && accessByFilter.length !== 0)
        || hasDraftFilter
        || archivedOnFromFilter
        || archivedOnToFilter;
      filterDropdown.toggleFilterMark($filterDropdown, filtersEnabled);
    }

    $.each([$publishedByFilter, $accessByFilter], function(_i, selector) {
      dropdownSelector.init(selector, {
        optionClass: 'checkbox-icon users-dropdown-list',
        optionLabel: (data) => {
          return `<img class="item-avatar" src="${data.params.avatar_url}"/> ${data.label}`;
        },
        tagLabel: (data) => {
          return `<img class="item-avatar" src="${data.params.avatar_url}"/> ${data.label}`;
        },
        labelHTML: true,
        tagClass: 'users-dropdown-list'
      });
    });

    $protocolsFilter.on('click', '#has_draft', function(e) {
      e.stopPropagation();
    });

    $filterDropdown.on('filter:apply', function() {
      publishedOnFromFilter = selectDate($publishedOnFromFilter);
      publishedOnToFilter = selectDate($publishedOnToFilter);
      modifiedOnFromFilter = selectDate($modifiedOnFromFilter);
      modifiedOnToFilter = selectDate($modifiedOnToFilter);
      publishedByFilter = dropdownSelector.getValues($('.published-by-filter'));
      accessByFilter = dropdownSelector.getValues($('.access-by-filter'));
      hasDraftFilter = $hasDraft.prop('checked') ? 'true' : '';
      archivedOnFromFilter = selectDate($archivedOnFromFilter);
      archivedOnToFilter = selectDate($archivedOnToFilter);
      protocolsViewSearch = $textFilter.val();

      appliedFiltersMark();
    });

    // Clear filters
    $filterDropdown.on('filter:clear', function() {
      dropdownSelector.clearData($publishedByFilter);
      dropdownSelector.clearData($accessByFilter);
      if ($publishedOnFromFilter.data('DateTimePicker')) $publishedOnFromFilter.data('DateTimePicker').clear();
      if ($publishedOnToFilter.data('DateTimePicker')) $publishedOnToFilter.data('DateTimePicker').clear();
      if ($modifiedOnFromFilter.data('DateTimePicker')) $modifiedOnFromFilter.data('DateTimePicker').clear();
      if ($modifiedOnToFilter.data('DateTimePicker')) $modifiedOnToFilter.data('DateTimePicker').clear();
      if ($archivedOnFromFilter.data('DateTimePicker')) $archivedOnFromFilter.data('DateTimePicker').clear();
      if ($archivedOnToFilter.data('DateTimePicker')) $archivedOnToFilter.data('DateTimePicker').clear();
      $hasDraft.prop('checked', false);
      $textFilter.val('');
    });

    // Prevent filter window close
    $filterDropdown.on('filter:clickBody', function() {
      $('#textSearchFilterHistory').hide();
      $textFilter.closest('.dropdown').removeClass('open');
      dropdownSelector.closeDropdown($publishedByFilter);
      dropdownSelector.closeDropdown($accessByFilter);
    });
  }

  // Initialize protocols DataTable
  function initProtocolsTable() {
    protocolsTableEl = $('#protocols-table');
    repositoryType = protocolsTableEl.data('type');

    protocolsDatatable = protocolsTableEl.DataTable({
      order: [[1, 'asc']],
      dom: "R<'main-actions hidden'<'toolbar'><'protocol-filters'f>>t<'pagination-row hidden'<'actions-toolbar'><'pagination-info'li><'pagination-actions'p>>",
      stateSave: true,
      sScrollX: '100%',
      sScrollXInner: '100%',
      buttons: [],
      processing: true,
      serverSide: true,
      ajax: {
        url: protocolsTableEl.data('source'),
        type: 'POST'
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
          return `<div class="sci-checkbox-container">
                    <input type="checkbox" class="sci-checkbox">
                    <span class="sci-checkbox-label"></span>
                  </div>`;
        }
      }, {
        targets: [1, 2, 3, 4, 5, 6, 7, 8, 9],
        searchable: true,
        orderable: true
      }],
      columns: [
        { data: '0' },
        { data: '1' },
        { data: '2' },
        { data: '3' },
        { data: '4' },
        {
          data: '5',
          visible: repositoryType !== 'archived'
        },
        { data: '6' },
        { data: '7' },
        { data: '8' },
        { data: '9' }
      ],
      oLanguage: {
        sSearch: I18n.t('general.filter')
      },
      rowCallback: function(row, data) {
        // Get row ID
        var rowId = data.DT_RowId;

        $(row).attr('data-row-id', rowId);

        if (data.DT_CanClone) {
          $(row).attr('data-can-clone', 'true');
          $(row).attr('data-clone-url', data.DT_CloneUrl);
        }
        if (data.DT_CanMakePrivate) { $(row).attr('data-can-make-private', 'true'); }
        if (data.DT_CanPublish) { $(row).attr('data-can-publish', 'true'); }
        if (data.DT_CanArchive) { $(row).attr('data-can-archive', 'true'); }
        if (data.DT_CanRestore) { $(row).attr('data-can-restore', 'true'); }
        if (data.DT_CanExport) { $(row).attr('data-can-export', 'true'); }

        // If row ID is in the list of selected row IDs
        if ($.inArray(rowId, rowsSelected) !== -1) {
          $(row).find("input[type='checkbox']").prop('checked', true);
          $(row).addClass('selected');
        }
      },
      fnDrawCallback: function() {
        animateSpinner(this, false);
        initRowSelection();
      },
      preDrawCallback: function() {
        animateSpinner(this);
      },
      stateSaveCallback: function(settings, data) {
        // Set a cookie with the table state using the team id
        localStorage.setItem(
          `datatables_protocols_state/${protocolsTableEl.data('team-id')}/${repositoryType}`,
          JSON.stringify(data)
        );
      },
      fnInitComplete: function(e) {
        var dataTableWrapper = $(e.nTableWrapper);
        DataTableHelpers.initLengthAppearance(dataTableWrapper);
        DataTableHelpers.initSearchField(dataTableWrapper, 'Enter...');
        dataTableWrapper.find('.main-actions, .pagination-row').removeClass('hidden');

        let actionToolBar = $($('#protocolActionToolbar').html());
        let generalToolbar = $($('#protocolGeneralToolbar').html());
        $('.protocols-container .actions-toolbar').html(actionToolBar);
        $('.protocols-container .toolbar').html(generalToolbar);

        let protocolFilters = $($('#protocolFilters').html());
        $(protocolFilters).prependTo('.protocols-container .protocol-filters');

        initProtocolsFilters();
      },
      stateLoadCallback: function() {
        // Load the table state for the current team
        var state = localStorage.getItem(`datatables_protocols_state/${protocolsTableEl.data('team-id')}/${repositoryType}`);
        if (state !== null) {
          return JSON.parse(state);
        }
        return null;
      }
    });

    $('#wrapper').on('sideBar::shown sideBar::hidden', function() {
      if (protocolsDatatable) {
        protocolsDatatable.columns.adjust();
      }
    });
  }

  function checkActionPermission(permission) {
    let allProtocols;

    allProtocols = rowsSelected.every((id) => {
      return protocolsTableEl.find(`tbody tr#${id}`).data(permission);
    });

    return allProtocols;
  }

  function loadPermission(id) {
    let row = protocolsTableEl.find(`tbody tr#${id}`);
    $.get(row.data('permissions-url'), (result) => {
      PERMISSIONS.forEach((permission) => {
        row.data(permission, result[permission]);
      });
      updateButtons();
    });
  }

  function initRowSelection() {
    let protocolsTableScrollHead = protocolsTableEl.closest('.dataTables_scroll').find('.dataTables_scrollHead');

    // Handle click on table cells with checkboxes
    protocolsTableEl.on('click', 'tbody td, thead th:first-child', function() {
      $(this).parent().find("input[type='checkbox']").trigger('click');
    });

    // Handle clicks on checkbox
    protocolsTableEl.find('tbody').on('click', "input[type='checkbox']", function(e) {
      // Get row ID
      var row = $(this).closest('tr');
      var data = protocolsDatatable.row(row).data();
      var rowId = data.DT_RowId;

      // Determine whether row ID is in the list of selected row IDs
      var index = $.inArray(rowId, rowsSelected);

      // If checkbox is checked and row ID is not in list of selected row IDs
      if (this.checked && index === -1) {
        rowsSelected.push(rowId);
        // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
      } else if (!this.checked && index !== -1) {
        rowsSelected.splice(index, 1);
      }

      updateDataTableSelectAllCheckbox();
      if (this.checked) {
        loadPermission(rowId);
        row.addClass('selected');
      } else {
        row.removeClass('selected');
        updateButtons();
      }

      e.stopPropagation();
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
    protocolsTableEl.find('tbody').on('click', "a[data-action='filter']", function(e) {
      var link = $(this);
      var query = link.attr('data-param');

      // Re-search data
      protocolsDatatable.search(query).draw();

      // Don't propagate this further up
      e.stopPropagation();
      return false;
    });
  }

  function initProtocolPreviewModal() {
    // Only do this if the repository is public/private
    if (repositoryType !== 'archive') {
      // If you are in protocol repository
      let protocolsEl = protocolsTableEl;
      // If you are in search results
      if (document.getElementById('search-content')) {
        protocolsEl = $('#search-content');
      }
      protocolsEl.on('click', "a[data-action='protocol-preview']", function(e) {
        var link = $(this);
        $.ajax({
          url: link.attr('data-url'),
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            var modal = $('#protocol-preview-modal');
            var modalTitle = modal.find('.modal-title');
            var modalBody = modal.find('.modal-body');
            var modalFooter = modal.find('.modal-footer');
            modalTitle.html(data.title);
            modalBody.html(data.html);
            modalFooter.html(data.footer);
            initHandsOnTable(modalBody);
            modal.modal('show');
            ProtocolRepositoryHeader.init();
            initHandsOnTable(modalBody);
            PdfPreview.initCanvas();
          },
          error: function() {
            // TODO
          }
        });
        e.preventDefault();
        return false;
      });
    }
  }

  function initVersionsModal() {
    let protocolsContainer = '.protocols-container';
    let versionsModal = '#protocol-versions-modal';

    protocolsTableEl.on('click', '.protocol-versions-link', function(e) {
      $.get(this.href, function(data) {
        $(protocolsContainer).append($.parseHTML(data.html));
        $(versionsModal).modal('show');

        // Remove modal when it gets closed
        $(versionsModal).on('hidden.bs.modal', function() {
          $(versionsModal).remove();
        });
      });
      e.stopPropagation();
      e.preventDefault();
    });
  }

  function initLinkedChildrenModal() {
    // Only do this if the repository is public/private
    if (repositoryType !== 'archive') {
      protocolsTableEl.on('click', "a[data-action='load-linked-children']", function(e) {
        var link = $(this);
        $.ajax({
          url: link.attr('data-url'),
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            var modal = $('#linked-children-modal');
            var modalTitle = modal.find('.modal-title');
            var modalBody = modal.find('.modal-body');
            modalTitle.html(data.title);
            modalBody.html(data.html);
            modal.modal('show');

            let childrenTableEl = modalBody.find('#linked-children-table');

            if (childrenTableEl) {
              // Only initialize table if it's present
              childrenTableEl.DataTable({
                autoWidth: false,
                dom: 'RBltpi',
                stateSave: false,
                buttons: [],
                processing: true,
                serverSide: true,
                ajax: {
                  url: childrenTableEl.data('source'),
                  type: 'POST'
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
                  { data: '1' }
                ],
                fnDrawCallback: function() {
                  animateSpinner(this, false);
                },
                preDrawCallback: function() {
                  animateSpinner(this);
                }
              });
            }
          },
          error: function() {
            // TODO
          }
        });

        e.preventDefault();
        return false;
      });
    }
  }

  function initModals() {
    function refresh(modal) {
      modal.find('.modal-body').html('');

      // Simply re-render table
      protocolsDatatable.ajax.reload();
    }

    // Make private modal hidden action
    $('#make-private-results-modal').on('hidden.bs.modal', function() {
      refresh($(this));
      updateDataTableSelectAllCheckbox();
      updateButtons();
    });

    // Publish modal hidden action
    $('#publish-results-modal').on('hidden.bs.modal', function() {
      refresh($(this));
      updateDataTableSelectAllCheckbox();
      updateButtons();
    });

    // Confirm archive modal hidden action
    $('#confirm-archive-modal').on('hidden.bs.modal', function() {
      // Unbind from click event on the submit button
      $(this).find(".modal-footer [data-action='submit']")
        .off('click');
    });

    // Archive modal hidden action
    $('#archive-results-modal').on('hidden.bs.modal', function() {
      refresh($(this));
      updateDataTableSelectAllCheckbox();
      updateButtons();
    });

    // Restore modal hidden action
    $('#restore-results-modal').on('hidden.bs.modal', function() {
      refresh($(this));
      updateDataTableSelectAllCheckbox();
      updateButtons();
    });

    // Linked children modal close action
    $('#linked-children-modal').on('hidden.bs.modal', function() {
      $(this).find('.modal-title').html('');
      // Destroy the embedded data table
      $(this).find('.modal-body #linked-children-table').DataTable().destroy();
      $(this).find('.modal-body').html('');
    });

    // Protocol preview modal close action
    $('#protocol-preview-modal').on('hidden.bs.modal', function() {
      $(this).find('.modal-title').html('');
      $(this).find('.modal-body').html('');
      $(this).find('.modal-footer').html('');
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
      if ('indeterminate' in checkboxSelectAll) {
        checkboxSelectAll.indeterminate = false;
      }
    } else if (checkboxesChecked.length === checkboxesAll.length) {
      // If all of the checkboxes are checked
      checkboxSelectAll.checked = true;
      if ('indeterminate' in checkboxSelectAll) {
        checkboxSelectAll.indeterminate = false;
      }
    } else {
      // If some of the checkboxes are checked
      checkboxSelectAll.checked = true;
      if ('indeterminate' in checkboxSelectAll) {
        checkboxSelectAll.indeterminate = true;
      }
    }
  }

  function updateButtons() {
    let actionToolbar = $('.protocols-container .actions-toolbar');
    $('.dataTables_wrapper').addClass('show-actions');

    if (rowsSelected.length === 0) {
      $('.dataTables_wrapper').removeClass('show-actions');
    } else if (rowsSelected.length === 1) {
      actionToolbar.find('.single-object-action, .multiple-object-action').removeClass('hidden');
    } else {
      actionToolbar.find('.single-object-action').addClass('hidden');
      actionToolbar.find('.multiple-object-action').removeClass('hidden');
    }

    PERMISSIONS.forEach((permission) => {
      if (!checkActionPermission(permission)) {
        actionToolbar.find(`.btn[data-for="${permission}"]`).addClass('hidden');
      }
    });

    if (protocolsDatatable) protocolsDatatable.columns.adjust();

    actionToolbar.find('.btn').addClass('notransition');
    actionToolbar.find('.btn').removeClass('btn-primary').addClass('btn-light');
    actionToolbar.find('.btn:visible').first().addClass('btn-primary').removeClass('btn-light');
    actionToolbar.find('.btn').removeClass('notransition');
  }

  /*
  function updateButtons() {
    var cloneBtn = $("[data-action='clone']");
    var makePrivateBtn = $("[data-action='make-private']");
    var publishBtn = $("[data-action='publish']");
    var archiveBtn = $("[data-action='archive']");
    var restoreBtn = $("[data-action='restore']");
    var exportBtn = $("[data-action='export']");
    var row = $("tr[data-row-id='" + rowsSelected[0] + "']");
    var rows = [];

    if (rowsSelected.length === 1) {
      // 1 ROW SELECTED
      if (row.is('[data-can-clone]')) {
        cloneBtn.removeClass('disabled hidden');
        cloneBtn.off('click').on('click', function() { cloneSelectedProtocol(); });
      } else {
        cloneBtn.removeClass('hidden').addClass('disabled');
        cloneBtn.off('click');
      }
      if (row.is('[data-can-make-private]')) {
        makePrivateBtn.removeClass('disabled hidden');
        makePrivateBtn.off('click').on('click', function() { processMoveButtonClick($(this)); });
      } else {
        makePrivateBtn.removeClass('hidden').addClass('disabled');
        makePrivateBtn.off('click');
      }
      if (row.is('[data-can-publish]')) {
        publishBtn.removeClass('disabled hidden');
        publishBtn.off('click').on('click', function() { processMoveButtonClick($(this)); });
      } else {
        publishBtn.removeClass('hidden').addClass('disabled');
        publishBtn.off('click');
      }
      if (row.is('[data-can-archive]')) {
        archiveBtn.removeClass('disabled hidden');
        archiveBtn.off('click').on('click', function() { processMoveButtonClick($(this)); });
      } else {
        archiveBtn.removeClass('hidden').addClass('disabled');
        archiveBtn.off('click');
      }
      if (row.is('[data-can-restore]')) {
        restoreBtn.removeClass('disabled hidden');
        restoreBtn.off('click').on('click', function() { processMoveButtonClick($(this)); });
      } else {
        restoreBtn.removeClass('hidden').addClass('disabled');
        restoreBtn.off('click');
      }
      if (row.is('[data-can-export]')) {
        exportBtn.removeClass('disabled hidden');
        exportBtn.off('click').on('click', function() { exportProtocols(rowsSelected); });
      } else {
        exportBtn.removeClass('hidden').addClass('disabled');
        exportBtn.off('click');
      }
    } else if (rowsSelected.length === 0) {
      // 0 ROWS SELECTED
      cloneBtn.addClass('disabled hidden');
      cloneBtn.off('click');
      makePrivateBtn.addClass('disabled hidden');
      makePrivateBtn.off('click');
      publishBtn.addClass('disabled hidden');
      publishBtn.off('click');
      archiveBtn.addClass('disabled hidden');
      archiveBtn.off('click');
      restoreBtn.addClass('disabled hidden');
      restoreBtn.off('click');
      exportBtn.addClass('disabled hidden');
      exportBtn.off('click');
    } else {
      // > 1 ROWS SELECTED
      _.each(rowsSelected, function(rowId) {
        rows.push($("tr[data-row-id='" + rowId + "']")[0]);
      });
      rows = $(rows);

      // Only enable button if all selected rows can
      // be published/archived/restored/exported
      cloneBtn.removeClass('hidden').addClass('disabled');
      cloneBtn.off('click');
      if (!rows.is(':not([data-can-make-private])')) {
        makePrivateBtn.removeClass('disabled hidden');
        makePrivateBtn.off('click').on('click', function() { processMoveButtonClick($(this)); });
      } else {
        makePrivateBtn.removeClass('hidden').addClass('disabled');
        makePrivateBtn.off('click');
      }
      if (!rows.is(':not([data-can-publish])')) {
        publishBtn.removeClass('disabled hidden');
        publishBtn.off('click').on('click', function() { processMoveButtonClick($(this)); });
      } else {
        publishBtn.removeClass('hidden').addClass('disabled');
        publishBtn.off('click');
      }
      if (!rows.is(':not([data-can-archive])')) {
        archiveBtn.removeClass('disabled hidden');
        archiveBtn.off('click').on('click', function() { processMoveButtonClick($(this)); });
      } else {
        archiveBtn.removeClass('hidden').addClass('disabled');
        archiveBtn.off('click');
      }
      if (!rows.is(':not([data-can-restore])')) {
        restoreBtn.removeClass('disabled hidden');
        restoreBtn.off('click').on('click', function() { processMoveButtonClick($(this)); });
      } else {
        restoreBtn.removeClass('hidden').addClass('disabled');
        restoreBtn.off('click');
      }
      if (!rows.is(':not([data-can-export])')) {
        exportBtn.removeClass('disabled hidden');
        exportBtn.off('click').on('click', function() { exportProtocols(rowsSelected); });
      } else {
        exportBtn.removeClass('hidden').addClass('disabled');
        exportBtn.off('click');
      }
    }
  }
  */

  /*
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

  */


  function initImport() {
    // Some templating code duplication. I know, I hate myself
    function newElement(name, values) {
      var template = $("[data-template='" + name + "']").clone();
      template.removeAttr('data-template');
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

    let importResultsModal = $('#import-results-modal');
    let fileInput = $("[data-role='import-file-input']");

    // Make sure multiple selections of same file
    // always prompt new modal
    fileInput.find("input[type='file']").on('click', function() {
      this.value = null;
    });

    // Hack to hide "No file chosen" tooltip
    fileInput.attr('title', window.webkitURL ? ' ' : '');

    fileInput.on('change', function(ev) {
      var importUrl = fileInput.attr('data-import-url');
      var teamId = fileInput.attr('data-team-id');
      var type = fileInput.attr('data-type');
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
            if (data.status === 'ok') {
              nrSuccessful += 1;

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
          let modalBody = importResultsModal.find('.modal-body');
          if (failed.length > 0) {
            let failedMessageEl = newElement(
              'import-result-message-error',
              {
                message: I18n.t('protocols.index.import_results.message_failed', { nr: failed.length })
              }
            );
            modalBody.append(failedMessageEl);
            animateSpinner(null, false);
          }
          if (nrSuccessful > 0) {
            let successMessageEl = newElement(
              'import-result-message-success',
              {
                message: I18n.t('protocols.index.import_results.message_ok', { nr: nrSuccessful })
              }
            );
            modalBody.append(successMessageEl);
          }
          let resultsListEl = newElement('import-result-list');
          modalBody.append(resultsListEl);
          if (unchanged.length > 0) {
            _.each(unchanged, function(pr) {
              var itemEl = newElement(
                'import-result-unchanged-item',
                { message: pr.name }
              );
              addChildToElement(resultsListEl, 'items', itemEl);
            });
          }
          if (renamed.length > 0) {
            _.each(renamed, function(pr) {
              var itemEl = newElement(
                'import-result-renamed-item',
                { message: I18n.t('protocols.index.row_renamed_html', { old_name: pr.name, new_name: pr.new_name }) }
              );
              addChildToElement(resultsListEl, 'items', itemEl);
            });
          }
          if (failed.length > 0) {
            _.each(failed, function(pr) {
              var itemEl = newElement(
                'import-result-failed-item',
                {
                  message: pr.name,
                  message2: (pr.status === 'size_too_large' ? I18n.t('protocols.index.import_results.row_file_too_large') : '')
                }
              );
              addChildToElement(resultsListEl, 'items', itemEl);
            });
          }

          importResultsModal.modal('show');
        }
      );
      $(this).val('');
    });
    importResultsModal.on('hidden.bs.modal', function() {
      importResultsModal.find('.modal-body').html('');

      // Also reload table
      protocolsDatatable.ajax.reload();
    });
  }

  init();
}());
