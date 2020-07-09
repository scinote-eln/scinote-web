/* global I18n animateSpinner HelperModule DataTableHelpers DataTableCheckboxes */
(function() {
  'use strict';

  var REPOSITORIES_TABLE;
  var CHECKBOX_SELECTOR;

  function updateActionButtons() {
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
    $.get($(tableTemplate).data('source'), {archived: archived}, function(data) {
      if (REPOSITORIES_TABLE) REPOSITORIES_TABLE.destroy();
      CHECKBOX_SELECTOR = null;
      $('.content-body').html(tableTemplate);
      REPOSITORIES_TABLE = $(tableContainer).DataTable({
        aaData: data,
        dom: "R<'main-actions hidden'<'toolbar'><'filter-container'f>>t<'pagination-row hidden'<'pagination-info'li><'pagination-actions'p>>",
        processing: true,
        pageLength: 25,
        colReorder: {
          enable: false
        },
        sScrollX: '100%',
        sScrollXInner: '100%',
        order: [[1, 'asc']],
        destroy: true,
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
        }],
        fnInitComplete: function(e) {
          var dataTableWrapper = $(e.nTableWrapper);
          CHECKBOX_SELECTOR = new DataTableCheckboxes(dataTableWrapper, {
            checkboxSelector: '.repository-row-selector',
            selectAllSelector: '.select-all-checkbox',
            onChanged: function() {
              updateActionButtons();
            }
          });
          DataTableHelpers.initLengthApearance(dataTableWrapper);
          DataTableHelpers.initSearchField(dataTableWrapper);
          $('.content-body .toolbar').html($('#repositoriesListButtons').html());
          dataTableWrapper.find('.main-actions, .pagination-row').removeClass('hidden');
          $('#createRepoBtn').initializeModal('#create-repo-modal');
          $('#deleteRepoBtn').initializeModal('#delete-repo-modal');
          $('#renameRepoBtn').initializeModal('#rename-repo-modal');
          $('#copyRepoBtn').initializeModal('#copy-repo-modal');
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

  function reloadSidebar() {
    var slidePanel = $('#slide-panel');
    $.get(slidePanel.data('sidebar-url'), {
      archived: $('.repositories-index').hasClass('archived')
    }, function(data) {
      slidePanel.html(data.html);
      $('.create-new-repository').initializeModal('#create-repo-modal');
    });
  }

  function initRepositoryViewSwitcher() {
    var viewSwitch = $('.view-switch');
    viewSwitch.on('click', '.view-switch-archived', function() {
      $('.repositories-index').removeClass('active').addClass('archived');
      initRepositoriesDataTable('#repositoriesList', true);
      reloadSidebar();
    });
    viewSwitch.on('click', '.view-switch-active', function() {
      $('.repositories-index').removeClass('archived').addClass('active');
      initRepositoriesDataTable('#repositoriesList');
      reloadSidebar();
    });
  }

  $('.repositories-index')
    .on('click', '#archiveRepoBtn', function() {
      $.post($('#archiveRepoBtn').data('archive-repositories'), {
        repository_ids: CHECKBOX_SELECTOR.selectedRows
      }, function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        initRepositoriesDataTable('#repositoriesList');
        reloadSidebar();
      }).fail(function(ev) {
        if (ev.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('repositories.js.permission_error'), ev.responseJSON.style);
        } else if (ev.status === 422) {
          HelperModule.flashAlertMsg(ev.responseJSON.error, 'danger');
        }
        animateSpinner(null, false);
      });
    })
    .on('click', '#restoreRepoBtn', function() {
      $.post($('#restoreRepoBtn').data('restore-repositories'), {
        repository_ids: CHECKBOX_SELECTOR.selectedRows
      }, function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        initRepositoriesDataTable('#repositoriesList', true);
        reloadSidebar();
      }).fail(function(ev) {
        if (ev.status === 403) {
          HelperModule.flashAlertMsg(I18n.t('repositories.js.permission_error'), ev.responseJSON.style);
        } else if (ev.status === 422) {
          HelperModule.flashAlertMsg(ev.responseJSON.error, 'danger');
        }
        animateSpinner(null, false);
      });
    });


  $('#wrapper').on('sideBar::hidden sideBar::shown', function() {
    if (REPOSITORIES_TABLE) {
      REPOSITORIES_TABLE.columns.adjust();
    }
  });

  $('.create-new-repository').initializeModal('#create-repo-modal');
  initRepositoriesDataTable('#repositoriesList', $('.repositories-index').hasClass('archived'));
  initRepositoryViewSwitcher();
}());
