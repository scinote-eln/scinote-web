//= require datatables
$('#samples').DataTable({
  order: [[2, 'desc']],
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
    searchable: false,
    orderable: false,
    sWidth: '1%'
  }, {
    targets: 1,
    searchable: false,
    orderable: true,
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
  }, {
    targets: 5,
    sWidth: '1%'
  }, {
    targets: 6,
    sWidth: '1%'
  }],
  columns: (function() {
    var numOfColumns = 7,
      columns = [],
      i = 0,
      visible;

    for (i; i < numOfColumns; i++) {
      visible = (i > 1 && i <= 6);
      columns.push({
        data: String(i),
        defaultContent: '',
        visible: visible
      });
    }
    return columns;
  })()
});
