var MyModuleRepositories = (function() {
  var SIMPLE_TABLE;

  function renderSimpleTable(tableContainer) {
    SIMPLE_TABLE = $(tableContainer).DataTable({
      dom: "Rt<'pagination-row'<'pagination-actions'p>>",
      processing: true,
      serverSide: true,
      responsive: true,
      pageLength: 5,
      order: [[3, 'asc']],
      sScrollX: '100%',
      sScrollXInner: '100%',
      destroy: true,
      ajax: {
        url: $(tableContainer).data('source'),
        data: function(d) {
          d.assigned = 'assigned';
          d.view_mode = true;
          d.skip_custom_columns = true;
        },
        global: false,
        type: 'GET'
      },
      columns: (function() {
        var columns = $(tableContainer).data('default-table-columns');
        for (let i = 0; i < columns.length; i += 1) {
          columns[i].data = String(i);
          columns[i].defaultContent = '';
        }
        return columns;
      }()),
      drawCallback: function() {
        var repositoryContainer = $(this).closest('.assigned-repository-container');
        repositoryContainer.find('.table.dataTable').removeClass('hidden');
        SIMPLE_TABLE.columns.adjust();
      }
    });
  }

  function initSimpleTable() {
    $('#assigned-items-container').on('show.bs.collapse', '.assigned-repository-container', function() {
      var repositoryContainer = $(this);
      var repositoryTemplate = $($('#my-module-repository-simple-template').html());
      repositoryTemplate.attr('data-source', $(this).data('repository-url'));
      repositoryContainer.html(repositoryTemplate);
      renderSimpleTable(repositoryTemplate);
    });
  }

  return {
    init: () => {
      initSimpleTable();
    }
  };
}());

MyModuleRepositories.init();
