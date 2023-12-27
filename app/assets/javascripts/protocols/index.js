//= require protocols/import_export/import
/* eslint-disable no-use-before-define, no-underscore-dangle, max-len, no-param-reassign */
/* global ProtocolRepositoryHeader PdfPreview DataTableHelpers importProtocolFromFile
   protocolFileImportModal PerfectSb protocolsIO
   protocolSteps dropdownSelector filterDropdown I18n animateSpinner initHandsOnTable inlineEditing HelperModule */

// Global variables
var ProtocolsIndex = (function() {
  const ALL_VERSIONS_VALUE = 'All';
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
    // window.initActionToolbar();
    // window.actionToolbarComponent.setReloadCallback(reloadTable);
    // make room for pagination
    // window.actionToolbarComponent.setBottomOffset(68);
    updateButtons();
    initProtocolsTable();
    initKeywordFiltering();
    initProtocolPreviewModal();
    initLinkedChildrenModal();
    initModals();
    initVersionsModal();
    initLocalFileImport();
  }

  function reloadTable() {
    rowsSelected = [];
    updateButtons();
    protocolsDatatable.ajax.reload();
  }

  function selectDate($field) {
    var datePicker = $field.data('dateTimePicker');
    if (datePicker && datePicker.date) {
      return datePicker.date.toString();
    }
    return null;
  }

  function initProtocolsFilters() {
    var $filterDropdown = filterDropdown.init(filtersEnabled);
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

    function getFilterValues() {
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
    }

    function filtersEnabled() {
      getFilterValues();

      return protocolsViewSearch
             || publishedOnFromFilter
             || publishedOnToFilter
             || modifiedOnFromFilter
             || modifiedOnToFilter
             || (publishedByFilter && publishedByFilter.length !== 0)
             || (accessByFilter && accessByFilter.length !== 0)
             || hasDraftFilter
             || archivedOnFromFilter
             || archivedOnToFilter;
    }

    function appliedFiltersMark() {
      filterDropdown.toggleFilterMark($filterDropdown, filtersEnabled());
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
      appliedFiltersMark();
      protocolsDatatable.ajax.reload();
    });

    // Clear filters
    $filterDropdown.on('filter:clear', function() {
      dropdownSelector.clearData($publishedByFilter);
      dropdownSelector.clearData($accessByFilter);

      $(this).find('input').val('');
      $publishedOnFromFilter.data('dateTimePicker')?.clearDate();
      $publishedOnToFilter.data('dateTimePicker')?.clearDate();
      $modifiedOnFromFilter.data('dateTimePicker')?.clearDate();
      $modifiedOnToFilter.data('dateTimePicker')?.clearDate();
      $archivedOnFromFilter.data('dateTimePicker')?.clearDate();
      $archivedOnToFilter.data('dateTimePicker')?.clearDate();
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

  function initManageAccess() {
    let protocolsContainer = '.protocols-container';

    $(protocolsContainer).on('click', '#manageProtocolAccess', function() {
      $(`tr[data-row-id=${rowsSelected[0]}] .protocol-users-link`).click();
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
        type: 'POST',
        data: function(data) {
          data.published_on_from = publishedOnFromFilter;
          data.published_on_to = publishedOnToFilter;
          data.modified_on_from = modifiedOnFromFilter;
          data.modified_on_to = modifiedOnToFilter;
          data.published_by = publishedByFilter;
          data.members = accessByFilter;
          data.has_draft = hasDraftFilter;
          data.archived_on_from = archivedOnFromFilter;
          data.archived_on_to = archivedOnToFilter;
          data.name_and_keywords = protocolsViewSearch;

          return data;
        }
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
        { data: '5' },
        { data: '6' },
        { data: '7' },
        { data: '8' },
        { data: '9' },
        {
          data: '10',
          visible: $('.protocols-index').hasClass('archived')
        },
        {
          data: '11',
          visible: $('.protocols-index').hasClass('archived')
        }
      ],
      oLanguage: {
        sSearch: I18n.t('general.filter')
      },
      rowCallback: function(row, data) {
        // Get row ID
        var rowId = data.DT_RowId;

        $(row).attr('data-row-id', rowId);

        // If row ID is in the list of selected row IDs
        if ($.inArray(rowId, rowsSelected) !== -1) {
          $(row).find("input[type='checkbox']").prop('checked', true);
          $(row).addClass('selected');
        }
      },
      fnDrawCallback: function() {
        animateSpinner(this, false);
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
        DataTableHelpers.initSearchField(dataTableWrapper, I18n.t('protocols.index.search_bar_placeholder'));
        dataTableWrapper.find('.main-actions, .pagination-row').removeClass('hidden');

        let generalToolbar = $($('#protocolGeneralToolbar').html());
        $('.protocols-container .toolbar').html(generalToolbar);

        let protocolFilters = $($('#protocolFilters').html());
        $(protocolFilters).appendTo('.protocols-container .protocol-filters');

        initProtocolsFilters();
        initRowSelection();
      },
      stateLoadParams: function(_, state) {
        state.search.search = '';
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

  function initRowSelection() {
    let protocolsTableScrollHead = protocolsTableEl.closest('.dataTables_scroll').find('.dataTables_scrollHead');

    // Handle click on table cells with checkboxes
    protocolsTableEl.on('click', 'tbody td, thead th:first-child', function(ev) {
      if (ev.target === ev.currentTarget) {
        $(this).parent().find("input[type='checkbox']").trigger('click');
      }
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
        row.addClass('selected');
      } else {
        row.removeClass('selected');
      }

      updateButtons();
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

    function loadVersionModal(href) {
      $.get(href, function(data) {
        $(protocolsContainer).append($.parseHTML(data.html));
        $(versionsModal).modal('show');
        inlineEditing.init();
        $(versionsModal).find('[data-toggle="tooltip"]').tooltip();

        // Remove modal when it gets closed
        $(versionsModal).on('hidden.bs.modal', function() {
          $(versionsModal).remove();
        });
      });
    }

    protocolsTableEl.on('click', '.protocol-versions-link', function(e) {
      loadVersionModal(this.href);
      e.stopPropagation();
      e.preventDefault();
    });

    $(protocolsContainer).on('click', '#protocolVersions', function(e) {
      e.stopPropagation();
      loadVersionModal($(`tr[data-row-id=${rowsSelected[0]}]`).data('versions-url'));
    });
  }

  function initdeleteDraftModal() {
    $('.protocols-index').on('click', '#protocol-versions-modal .delete-draft', function() {
      let url = this.dataset.url;
      let modal = $('#deleteDraftModal');
      $('#protocol-versions-modal').modal('hide');
      modal.modal('show');
      modal.find('form').attr('action', url);
    });

    $('#deleteDraftModal form').on('ajax:error', function(_ev, data) {
      HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
    });
  }

  function initProtocolsioModal() {
    $('#protocolsioModal').on('show.bs.modal', function() {
      if ($(this).find('.modal-body').length === 0) {
        $.get(this.dataset.url, function(data) {
          $('#protocolsioModal').find('.modal-content').html(data.html);
          protocolsIO();
          protocolSteps();
          PerfectSb().init();
        });
      }
    });
  }

  function initArchiveProtocols() {
    $('.protocols-index').on('click', '#archiveProtocol', function(e) {
      archiveProtocols(e.currentTarget.dataset.url, rowsSelected);
    });
  }

  function archiveProtocols(url, ids) {
    $.post(url, { protocol_ids: ids }, (data) => {
      HelperModule.flashAlertMsg(data.message, 'success');
      reloadTable();
    }).fail((data) => {
      HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
    });
  }

  function initRestoreProtocols() {
    $('.protocols-index').on('click', '#restoreProtocol', function(e) {
      restoreProtocol(e.currentTarget.dataset.url, rowsSelected);
    });
  }

  function restoreProtocol(url, ids) {
    $.post(url, { protocol_ids: ids }, (data) => {
      HelperModule.flashAlertMsg(data.message, 'success');
      reloadTable();
    }).fail((data) => {
      HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
    });
  }

  function initExportProtocols() {
    $('.protocols-index').on('click', '#exportProtocol', function(e) {
      exportProtocols(e.currentTarget.dataset.url, rowsSelected);
    });
  }

  function exportProtocols(url, ids) {
    if (ids.length > 0) {
      let params = '?protocol_ids[]=' + ids[0];
      for (let i = 1; i < ids.length; i += 1) {
        params += '&protocol_ids[]=' + ids[i];
      }
      params = encodeURI(params);
      window.location.href = url + params;
    }
  }

  function initDuplicateProtocols() {
    $('.protocols-index').on('click', '#duplicateProtocol', function() {
      duplicateProtocols($(this));
    });
  }

  function duplicateProtocols($el) {
    $.ajax({
        type: 'POST',
        url: $el.data('url'),
        data: JSON.stringify({ ids: rowsSelected }),
        contentType: 'application/json'
    }).done((data) => {
      animateSpinner(null, false);
      HelperModule.flashAlertMsg(data.message, 'success');
      reloadTable();
    }).fail((data) => {
      animateSpinner(null, false);
      HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
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
            let versionFromDropdown = ALL_VERSIONS_VALUE;

            const initVersionsDropdown = (childrenDatatable) => {
              const versionSelector = $('#version-selector');
              dropdownSelector.init(versionSelector, {
                noEmptyOption: true,
                singleSelect: true,
                selectAppearance: 'simple',
                closeOnSelect: true,
                onSelect: function() {
                  versionFromDropdown = dropdownSelector.getValues(versionSelector);
                  childrenDatatable.ajax.reload();
                }
              });
            };

            let childrenDatatable;

            if (childrenTableEl) {
              // Only initialize table if it's present
              childrenDatatable = childrenTableEl.DataTable({
                autoWidth: false,
                dom: 'RBtpl',
                stateSave: false,
                buttons: [],
                processing: true,
                serverSide: true,
                ajax: {
                  url: childrenTableEl.data('source'),
                  type: 'POST',
                  data: function(d) {
                    if (versionFromDropdown !== ALL_VERSIONS_VALUE) {
                      d.version = versionFromDropdown;
                    }

                    return d;
                  }
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
                lengthMenu: [
                  [10, 25, 50],
                  [
                    I18n.t('protocols.index.linked_children.length_menu', { number: 10 }),
                    I18n.t('protocols.index.linked_children.length_menu', { number: 25 }),
                    I18n.t('protocols.index.linked_children.length_menu', { number: 50 })
                  ]
                ],
                language: {
                  lengthMenu: '_MENU_'
                },
                fnDrawCallback: function() {
                  animateSpinner(this, false);
                },
                preDrawCallback: function() {
                  animateSpinner(this);
                }
              });
            }

            initVersionsDropdown(childrenDatatable);
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
    // Linked children modal close action
    $('#linked-children-modal').on('hidden.bs.modal', function() {
      $(this).find('.modal-title').html('');
      // Destroy the embedded data table
      $(this).find('.modal-body #linked-children-table').DataTable().destroy();
      $(this).find('.modal-body').html('');
    });
  }

  function updateDataTableSelectAllCheckbox() {
    var table = $('.protocols-datatable');
    var checkboxes = table.find("tbody input[type='checkbox']");
    var selectedCheckboxes = table.find("tbody input[type='checkbox']:checked");
    var selectAllCheckbox = table.find("thead input[name='select_all']");

    selectAllCheckbox.prop('indeterminate', false);
    if (selectedCheckboxes.length === 0) {
      selectAllCheckbox.prop('checked', false);
    } else if (selectedCheckboxes.length === checkboxes.length) {
      selectAllCheckbox.prop('checked', true);
    } else {
      selectAllCheckbox.prop('indeterminate', true);
    }
  }

  function updateButtons() {
  }

  function initLocalFileImport() {
    let fileInput = $("[data-role='import-file-input']");

    // Make sure multiple selections of same file
    // always prompt new modal
    fileInput.find("input[type='file']").on('click', function() {
      this.value = null;
    });

    // Hack to hide "No file chosen" tooltip
    fileInput.attr('title', window.webkitURL ? ' ' : '');

    fileInput.on('click', (ev) => {
      ev.target.value = null;
    });

    fileInput.on('change', function(ev) {
      var importUrl = fileInput.attr('data-import-url');
      var teamId = fileInput.attr('data-team-id');
      var type = fileInput.attr('data-type');
      if(ev.target.files[0].name.split('.').pop() === 'eln') {
        importProtocolFromFile(
          ev.target.files[0],
          importUrl,
          { team_id: teamId, type: type },
          false,
          function(datas) {
            var nrSuccessful = 0;
            _.each(datas, function(data) {
              if (data.status === 'ok') {
                nrSuccessful += 1;
              }
            });
            animateSpinner(null, false);

            if (nrSuccessful) {
              HelperModule.flashAlertMsg(I18n.t('protocols.index.import_results.message_ok_html', { count: nrSuccessful }), 'success');
              window.protocolsTable.$refs.table.updateTable();
            } else {
              HelperModule.flashAlertMsg(I18n.t('protocols.index.import_results.message_failed'), 'danger');
            }
          }
        );
      } else {
        protocolFileImportModal.init(ev.target.files, window.protocolsTable.$refs.table.updateTable());
      }
      // $(this).val('');
    });
  }

  init();
  initManageAccess();
  initArchiveProtocols();
  initRestoreProtocols();
  initExportProtocols();
  initDuplicateProtocols();
  initdeleteDraftModal();
  initProtocolsioModal();

  return {
    reloadTable: function() {
      reloadTable();
    }
  };
}());
