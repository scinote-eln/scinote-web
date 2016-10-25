//= require datatables
$('#samples').DataTable({
  order: [[0, 'desc']],
  dom: "RB<'row'<'col-sm-9-custom toolbar'l><'col-sm-3-custom'f>>ti",
  stateSave: false,
  buttons: [],
  bPaginate: false,
  searching: false,
  processing: true,
  serverSide: true,
  ajax: {
    url: $('#samples').data('source'),
    global: false,
    type: 'POST'
  },
  colReorder: {
    fixedColumnsLeft: 1000000 // Disable reordering
  },
  columnDefs: [{
    targets: 0,
    sWidth: '1%'
  }, {
    targets: 1,
    sWidth: '1%'
  }, {
    targets: 2,
    sWidth: '1%'
  }, {
    targets: 3,
    sWidth: '1%'
  }, {
    targets: 4,
    sWidth: '1%'
  }],
  columns: (function() {
    var numOfColumns = 5,
      columns = [],
      i = 0;

    for (i; i < numOfColumns; i++) {
      columns.push({
        data: String(i),
        defaultContent: ''
      });
    }
    return columns;
  })()
});
