//= require datatables

table = $("#samples").DataTable({
    order: [[2, "desc"]],
    dom: "RB<'row'<'col-sm-9-custom toolbar'l><'col-sm-3-custom'f>>ti",
    stateSave: false,
    buttons: [],
    bPaginate: false,
    searching: false,
    processing: true,
    serverSide: true,
    ajax: {
        url: $("#samples").data("source"),
        global: false,
        type: "POST"
    },
    colReorder: {
        fixedColumnsLeft: 1000000 // Disable reordering
    },
    columnDefs: [{
        targets: 0,
        searchable: false,
        orderable: false,
        className: "dt-body-center",
        sWidth: "1%",
        render: function (data, type, full, meta){
            return "<input type='checkbox'>";
        }
    }, {
        targets: 1,
        searchable: false,
        orderable: true,
        sWidth: "1%"
    }],
    columns: (function() {
        var numOfColumns = $("#samples").data("num-columns");
        var columns = [];

        for (var i = 0; i < numOfColumns; i++) {
            var visible = (i > 0 && i <= 6);
            columns.push({
                data: i + "",
                defaultContent: "",
                visible: visible
            });
        }
        return columns;
    })(),
    fnDrawCallback: function(settings, json) {
        animateSpinner(this, false);
    },
    preDrawCallback: function(settings) {
        animateSpinner(this);
        $(".sample_info").off("click");
    }
});
