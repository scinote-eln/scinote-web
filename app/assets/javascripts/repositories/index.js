/* global I18n animateSpinner HelperModule
          DataTableHelpers DataTableCheckboxes notTurbolinksPreview */
(function() {
  'use strict';

  var REPOSITORIES_TABLE;
  var CHECKBOX_SELECTOR;

  function updateActionButtons() {
    if (window.actionToolbarComponent) {
      window.actionToolbarComponent.fetchActions({ repository_ids: CHECKBOX_SELECTOR.selectedRows });
      $('.dataTables_scrollBody').css('padding-bottom', `${CHECKBOX_SELECTOR.selectedRows.length > 0 ? 68 : 0}px`);
    }

    var rowsCount = CHECKBOX_SELECTOR.selectedRows.length;
    var row;
    $('#renameRepoBtn').attr('href', '#');
    $('#deleteRepoBtn').attr('href', '#');
    $('#copyRepoBtn').attr('href', '#');
    switch (rowsCount) {
      case 0:
        $('.main-actions [data-action-mode="single"]').addClass('disabled hidden');
        $('.main-actions [data-action-mode="multiple"]').addClass('disabled hidden');
        break;
      case 1:
        row = $('#repositoriesList').find('tr#' + CHECKBOX_SELECTOR.selectedRows[0]);
        $('.main-actions [data-action-mode="single"]').removeClass('disabled hidden');
        $('.main-actions [data-action-mode="multiple"]').removeClass('disabled hidden');
        $('#renameRepoBtn').attr('href', row.data('rename-modal-url'));
        $('#deleteRepoBtn').attr('href', row.data('delete-modal-url'));
        $('#copyRepoBtn').attr('href', row.data('copy-modal-url'));
        break;
      default:
        $('.main-actions [data-action-mode="single"]').removeClass('hidden').addClass('disabled');
        $('.main-actions [data-action-mode="multiple"]').removeClass('disabled hidden');
    }
  }

  function initRepositoriesDataTable(tableContainer, archived = false) {
    var tableTemplate = $('#RepositoriesListTable').html();
    $.get($(tableTemplate).data('source'), { archived: archived }, function(data) {
      if (REPOSITORIES_TABLE) REPOSITORIES_TABLE.destroy();
      CHECKBOX_SELECTOR = null;
      $('.content-body').html(tableTemplate);
      REPOSITORIES_TABLE = $(tableContainer).DataTable({
        aaData: data,
        dom: "R<'main-actions hidden'<'toolbar'><'filter-container'f>>t<'pagination-row hidden'<'pagination-info'li><'pagination-actions'p>>",
        processing: true,
        stateSave: true,
        pageLength: 25,
        colReorder: {
          enable: false
        },
        sScrollX: '100%',
        sScrollXInner: '100%',
        order: [[1, 'asc']],
        destroy: true,
        language: {
          emptyTable: archived ? I18n.t('repositories.index.no_archived_inventories') : I18n.t('repositories.index.no_inventories'),
          zeroRecords: archived ? I18n.t('repositories.index.no_archived_inventories_matched') : I18n.t('repositories.index.no_inventories_matched')
        },
        columnDefs: [{
          targets: 0,
          visible: !$('.repositories-index').data('readonly'),
          searchable: false,
          orderable: false,
          render: function() {
            return `<div class="sci-checkbox-container">
                      <input class='repository-row-selector sci-checkbox' type='checkbox'>
                      <span class='sci-checkbox-label'></span>
                    </div>`;
          }
        }, {
          targets: 1,
          className: 'item-name',
          render: function(value, type, row) {
            return `<a href="${row.repositoryUrl}">${value}</a>`;
          }
        }, {
          targets: 5,
          render: {
            _: 'display',
            sort: 'sort'
          }
        }, {
          targets: 7,
          visible: archived,
          render: {
            _: 'display',
            sort: 'sort'
          }
        }, {
          targets: 8,
          visible: archived
        },
        {
          visible: true,
          searchable: false,
          data: 'stock',
          render: {
            _: 'display',
            sort: 'sort'
          }
        }],
        fnInitComplete: function(e) {
          initActionToolbar();
          window.actionToolbarComponent.setReloadCallback(() =>
            initRepositoriesDataTable('#repositoriesList', archived));
          window.actionToolbarComponent.setBottomOffset(68);

          var dataTableWrapper = $(e.nTableWrapper);
          CHECKBOX_SELECTOR = new DataTableCheckboxes(dataTableWrapper, {
            checkboxSelector: '.repository-row-selector',
            selectAllSelector: '.select-all-checkbox',
            onChanged: function() {
              updateActionButtons();
            }
          });

          updateActionButtons();
          DataTableHelpers.initLengthAppearance(dataTableWrapper);
          DataTableHelpers.initSearchField(dataTableWrapper, I18n.t('repositories.index.filter_inventory'));
          $('.content-body .toolbar').html($('#repositoriesListButtons').html());
          dataTableWrapper.find('.main-actions, .pagination-row').removeClass('hidden');

          $('#createRepoBtn').initSubmitModal('#create-repo-modal', 'repository');
          $('#deleteRepoBtn').initSubmitModal('#delete-repo-modal', 'repository');
          $('#renameRepoBtn').initSubmitModal('#rename-repo-modal', 'repository');
          $('#copyRepoBtn').initSubmitModal('#copy-repo-modal', 'repository');
        },
        drawCallback: function() {
          if (CHECKBOX_SELECTOR) CHECKBOX_SELECTOR.checkSelectAllStatus();
        },
        rowCallback: function(row) {
          let $row = $(row);
          let checkbox = $row.find('.repository-row-selector');

          if ($row.attr('data-shared') === 'true') {
            checkbox.attr('disabled', 'disabled');
          }

          if (CHECKBOX_SELECTOR) CHECKBOX_SELECTOR.checkRowStatus(row);
        }
      });
    });
  }

  $('#wrapper').on('sideBar::hidden sideBar::shown', function() {
    if (REPOSITORIES_TABLE) {
      REPOSITORIES_TABLE.columns.adjust();
    }
  });

  $(document).on('shown.bs.modal', function() {
    var inputField = $('#repository_name');
    var value = inputField.val();
    inputField.focus().val('').val(value);
  });
  
  $('.create-new-repository').initSubmitModal('#create-repo-modal', 'repository');
  if (notTurbolinksPreview()) {
    initRepositoriesDataTable('#repositoriesList', $('.repositories-index').hasClass('archived'));
  }
}());
