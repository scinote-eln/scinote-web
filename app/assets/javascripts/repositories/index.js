/* global DataTableHelpers */
(function() {
  'use strict';

  var REPOSITORIES_TABLE;

  function initRepositoriesDataTable(tableContainer) {
    if (REPOSITORIES_TABLE) REPOSITORIES_TABLE.destroy();
    $('.content-body').html($('#activeRepositoriesListTable').html());
    $.get($(tableContainer).data('source'), function(data) {
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

        fnInitComplete: function() {
          var dataTableWrapper = $(tableContainer).closest('.dataTables_wrapper');
          DataTableHelpers.initLengthApearance(dataTableWrapper);
          DataTableHelpers.initSearchField(dataTableWrapper);
          $('.content-body .toolbar').html($('#activeRepositoriesListButtons').html());
          dataTableWrapper.find('.main-actions, .pagination-row').removeClass('hidden');
          $('.create-new-repository').initializeModal('#create-repo-modal');
        }
      });
    });
  }

  initRepositoriesDataTable('#repositoriesList');
}());
