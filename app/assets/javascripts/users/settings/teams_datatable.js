// Initialize teams DataTable
function initTeamsTable() {
  teamsDatatable = $('#teams-table').DataTable({
    order: [[0, 'asc']],
    dom: 'RBltpi',
    stateSave: true,
    buttons: [],
    processing: true,
    serverSide: true,
    ajax: {
      url: $('#teams-table').data('source'),
      type: 'POST'
    },
    colReorder: {
      fixedColumnsLeft: 1000000 // Disable reordering
    },
    columnDefs: [{
      targets: [0, 1],
      orderable: true,
      searchable: false
    }, {
      targets: 2,
      searchable: false,
      orderable: true
    }, {
      targets: 3,
      searchable: false,
      orderable: false,
      sWidth: '1%'
    }]
  });
}

initTeamsTable();
