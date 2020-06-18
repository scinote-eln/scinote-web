/* global HelperModule DataTableHelpers DataTableCheckboxes */
(function(global) {
  'use strict';

  var REPOSITORIES_TABLE;
  var CHECKBOX_SELECTOR;

  function initRepositoriesDataTable(tableContainer, archived = false) {
    var tableTemplate = archived ? $('#archivedRepositoriesListTable').html() : $('#activeRepositoriesListTable').html();
    $.get($(tableTemplate).data('source'), function(data) {
      if (REPOSITORIES_TABLE) REPOSITORIES_TABLE.destroy();
      CHECKBOX_SELECTOR = null;
      $('.content-body').html(tableTemplate);
      REPOSITORIES_TABLE = $(tableContainer).DataTable({
        aaData: data,
        dom: "R<'main-actions hidden'<'toolbar'><'filter-container'f>>t<'pagination-row hidden'<'pagination-info'li><'pagination-actions'p>>",
        processing: true,
        pageLength: 25,
        sScrollX: '100%',
        sScrollXInner: '100%',
        order: [[1, 'asc']],
        destroy: true,
        columnDefs: [{
          targets: 0,
          visible: true,
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
          render: function(value, type, row) {
            return `<a href="${row.repositoryUrl}">${value}</a>`;
          }
        }],
        fnInitComplete: function(e) {
          var dataTableWrapper = $(e.nTableWrapper);
          CHECKBOX_SELECTOR = new DataTableCheckboxes(dataTableWrapper, {
            checkboxSelector: '.repository-row-selector',
            selectAllSelector: '.select-all-checkbox'
          });
          DataTableHelpers.initLengthApearance(dataTableWrapper);
          DataTableHelpers.initSearchField(dataTableWrapper);
          $('.content-body .toolbar').html($('#repositoriesListButtons').html());
          dataTableWrapper.find('.main-actions, .pagination-row').removeClass('hidden');
          $('.create-new-repository').initializeModal('#create-repo-modal');
        },
        drawCallback: function() {
          if (CHECKBOX_SELECTOR) CHECKBOX_SELECTOR.checkSelectAllStatus();
        },
        rowCallback: function(row) {
          if (CHECKBOX_SELECTOR) CHECKBOX_SELECTOR.checkRowStatus(row);
        }
      });
    });
  }

  function reloadSidebar() {
    var slidePanel = $('#slide-panel');
    var archived;
    if ($('.repositories-index').hasClass('archived')) archived = true;
    $.get(slidePanel.data('sidebar-url'), { archived: archived }, function(data) {
      slidePanel.html(data.html);
    });
  }

  function initRepositoryViewSwitcher() {
    var viewSwitch = $('.view-switch');
    viewSwitch.on('click', '.view-switch-archived', function() {
      $('.repositories-index').toggleClass('archived active');
      initRepositoriesDataTable('#repositoriesList', true);
      reloadSidebar();
    });
    viewSwitch.on('click', '.view-switch-active', function() {
      $('.repositories-index').toggleClass('archived active');
      initRepositoriesDataTable('#repositoriesList');
      reloadSidebar();
    });
  }

  global.onClickArchiveRepositories = function() {
    $.ajax({
      url: $('#archiveRepoBtn').data('archive-repositories'),
      type: 'POST',
      dataType: 'json',
      data: { selected_repos: CHECKBOX_SELECTOR.selectedRows },
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        initRepositoriesDataTable('#repositoriesList');
        reloadSidebar();
      }
    });
  };

  global.onClickRestoreRepositories = function() {
    $.ajax({
      url: $('#restoreRepoBtn').data('restore-repositories'),
      type: 'POST',
      dataType: 'json',
      data: { selected_repos: CHECKBOX_SELECTOR.selectedRows },
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        initRepositoriesDataTable('#repositoriesList', true);
        reloadSidebar();
      }
    });
  };

  initRepositoriesDataTable('#repositoriesList');
  initRepositoryViewSwitcher();
}(window));
