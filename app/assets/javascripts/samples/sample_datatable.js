var rowsSelected = [];

// Tells whether we're currently viewing or editing table
var currentMode = "viewMode";

// Tells what action will execute by pressing on save button (update/create)
var saveAction = "update";
var selectedSample;

table = $("#samples").DataTable({
    order: [[2, "desc"]],
    dom: "RB<'row'<'col-sm-9 toolbar'l><'col-sm-3'f>>tpi",
    stateSave: true,
    buttons: [{
        extend: "colvis",
        text: function () {
            return '<span class="glyphicon glyphicon-option-horizontal"></span> ' +
                '<span class="hidden-xs">' +
                I18n.t('samples.column_visibility') +
                '</span>';
        },
        columns: ":gt(2)"
    }],
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
    rowCallback: function(row, data, dataIndex){
        // Get row ID
        var rowId = data["DT_RowId"];

        // If row ID is in the list of selected row IDs
        if($.inArray(rowId, rowsSelected) !== -1){
            $(row).find('input[type="checkbox"]').prop('checked', true);

            $(row).addClass('selected');
        }
    },
    columns: (function() {
        var numOfColumns = $("#samples").data("num-columns");
        var columns = [];

        for (var i = 0; i < numOfColumns; i++) {
            var visible = (i <= 6);
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
        changeToViewMode();
        updateButtons();
    },
    stateLoadParams: function(settings, data) {
        // Check if URL parameters contain the column to show, if so, display it
        // no matter what
        if (getParam("new_col") !== null &&
            data.columns.length === $("#samples").data("num-columns") - 1) {
            // # of columns grew to +1, we need to add new column to data!
            var i = data.columns.length + "";
            data.columns.push({
                data: i,
                defaultContent: "",
                visible: true
            });
        }
    },
    stateSaveCallback: function (settings, data) {
        // Set a cookie with the table state using the organization id
        localStorage.setItem('datatables_state/' + $("#samples").attr("data-organization-id"), JSON.stringify(data));
    },
    stateLoadCallback: function (settings) {
        // Load the table state for the current organization
        var state = localStorage.getItem('datatables_state/' + $("#samples").attr("data-organization-id"));
        if (state !== null) {
           return JSON.parse(state);
        }
        return null;
    },
    preDrawCallback: function(settings) {
        animateSpinner(this);
    }
});

table.buttons().container().appendTo('#datatables-buttons');

// Enables noSearchHidden plugin
$.fn.dataTable.defaults.noSearchHidden = true

// Append button to inner toolbar in table
$("div.toolbarButtons").appendTo("div.toolbar");
$("div.toolbarButtons").show();

$(".delete_samples_submit").click(function () {
    animateLoading();
});

$("#assignSamples, #unassignSamples").click(function () {
    animateLoading();
});

// Updates "Select all" control in a data table
function updateDataTableSelectAllCtrl(table){
    var $table             = table.table().node();
    var $chkbox_all        = $('tbody input[type="checkbox"]', $table);
    var $chkbox_checked    = $('tbody input[type="checkbox"]:checked', $table);
    var chkbox_select_all  = $('thead input[name="select_all"]', $table).get(0);

    // If none of the checkboxes are checked
    if($chkbox_checked.length === 0){
        chkbox_select_all.checked = false;
        if('indeterminate' in chkbox_select_all){
            chkbox_select_all.indeterminate = false;
        }

        // If all of the checkboxes are checked
    } else if ($chkbox_checked.length === $chkbox_all.length){
        chkbox_select_all.checked = true;
        if('indeterminate' in chkbox_select_all){
            chkbox_select_all.indeterminate = false;
        }

        // If some of the checkboxes are checked
    } else {
        chkbox_select_all.checked = true;
        if('indeterminate' in chkbox_select_all){
            chkbox_select_all.indeterminate = true;
        }
    }
}

// Handle click on table cells with checkboxes
$('#samples').on('click', 'tbody td, thead th:first-child', function(e){
    $(this).parent().find('input[type="checkbox"]').trigger('click');
});

// Handle clicks on checkbox
$("#samples tbody").on("click", "input[type='checkbox']", function(e){
    if (currentMode != "viewMode")
        return false;

    // Get row ID
    var $row = $(this).closest("tr");
    var data = table.row($row).data();
    var rowId = data["DT_RowId"];

    // Determine whether row ID is in the list of selected row IDs
    var index = $.inArray(rowId, rowsSelected);

    // If checkbox is checked and row ID is not in list of selected row IDs
    if(this.checked && index === -1){
        rowsSelected.push(rowId);
        // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
    } else if (!this.checked && index !== -1){
        rowsSelected.splice(index, 1);
    }

    if(this.checked){
        $row.addClass('selected');
    } else {
        $row.removeClass('selected');
    }

    updateDataTableSelectAllCtrl(table);

    e.stopPropagation();

    updateButtons();
});

// Handle click on "Select all" control
$('#samples thead input[name="select_all"]').on('click', function(e){
    if(this.checked){
        $('#samples tbody input[type="checkbox"]:not(:checked)').trigger('click');
    } else {
        $('#samples tbody input[type="checkbox"]:checked').trigger('click');
    }

    // Prevent click event from propagating to parent
    e.stopPropagation();
});

// Append selected samples to form
$("form#form-samples").submit(function(e){
    var form = this;

    if (currentMode == "viewMode")
        appendSamplesIdToForm(form);
});

// Append selected samples and headers form
$("form#form-export").submit(function(e){
    var form = this;

    if (currentMode == "viewMode") {
        // Remove all hidden fields
        $("#form-export").find("input[name=sample_ids\\[\\]]").remove();
        $("#form-export").find("input[name=header_ids\\[\\]]").remove();

        // Append samples
        appendSamplesIdToForm(form);

        // Append visible column information
        $("table#samples thead tr").children("th").each(function(i) {
            var th = $(this);
            var val;

            if ($(th).attr("id") == "sample-name")
                val = -1;
            else if ($(th).attr("id") == "sample-type")
                val = -2;
            else if ($(th).attr("id") == "sample-group")
                val = -3;
            else if ($(th).attr("id") == "added-by")
                val = -4;
            else if ($(th).attr("id") == "added-on")
                val = -5;
            else if ($(th).hasClass("custom-field"))
                val = th.attr("id");

            if (val)
                $(form).append(
                    $('<input>')
                    .attr('type', 'hidden')
                    .attr('name', 'header_ids[]')
                    .val(val)
                );
        });

    }
});

function appendSamplesIdToForm(form) {
    $.each(rowsSelected, function(index, rowId){
        $(form).append(
            $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'sample_ids[]')
            .val(rowId)
        );
    });
}

// Handle table draw event
table.on('draw', function(){
    updateDataTableSelectAllCtrl(table);
});

// Edit sample
function onClickEdit() {
    if (rowsSelected.length != 1) return;

    var row = table.row("#" + rowsSelected[0]);
    var node = row.node();
    var rowData = row.data();

    $(node).find("td input").trigger("click");
    selectedSample = node;

    clearAllErrors();
    changeToEditMode();
    updateButtons();
    saveAction = "update";

    $.ajax({
        url: rowData["sampleInfoUrl"],
        type: "GET",
        dataType: "json",
        success: function (data) {
            // Show save and cancel buttons in first two columns
            $(node).children("td").eq(0).html($("#saveSample").clone());
            $(node).children("td").eq(1).html($("#cancelSave").clone());

            // Sample name column
            var colIndex = getColumnIndex("#sample-name");
            if (colIndex) {
                $(node).children("td").eq(colIndex).html(changeToInputField("sample", "name", data["sample"]["name"]));
            }

            // Sample type column
            var colIndex = getColumnIndex("#sample-type");
            if (colIndex) {
                var selectType = createSampleTypeSelect(data["sample_types"], data["sample"]["sample_type"]);
                $(node).children("td").eq(colIndex).html(selectType);
                $("select[name=sample_type_id]").selectpicker();
            }

            // Sample group column
            var colIndex = getColumnIndex("#sample-group");
            if (colIndex) {
                var selectGroup = createSampleGroupSelect(data["sample_groups"], data["sample"]["sample_group"]);
                $(node).children("td").eq(colIndex).html(selectGroup);
                $("select[name=sample_group_id]").selectpicker();
            }

            // Take care of custom fields
            var cfields = data["sample"]["custom_fields"];
            $(node).children("td").each(function(i) {
                var td = $(this);
                var rawIndex = table.column.index("fromVisible", i);
                var colHeader = table.column(rawIndex).header();
                if ($(colHeader).hasClass("custom-field")) {
                    // Check if custom field on this sample exists
                    var cf = cfields[$(colHeader).attr("id")];
                    if (cf)
                        td.html(changeToInputField("sample_custom_fields", cf["sample_custom_field_id"], cf["value"]));
                    else
                        td.html(changeToInputField("custom_fields", $(colHeader).attr("id"), ""));
                }
            });
        },
        error: function (e, data, status, xhr) {
            if (e.status == 403) {
                sampleAlertMsg(I18n.t("samples.js.permission_error"), "danger");
                changeToViewMode();
                updateButtons();
            }
        }
    });
}

// Save sample
function onClickSave() {
    if (saveAction == "update") {
        var row = table.row(selectedSample);
        var node = row.node();
        var rowData = row.data();
    } else if (saveAction == "create")
        var node = selectedSample;

    // First fetch all the data in input fields
    data = {
        sample_id: $(selectedSample).attr("id"),
        sample: {},
        custom_fields: {}, // These fields are not currently bound to this sample
        sample_custom_fields: {} // These fields are already in database (linked to this sample)
    };

    // Direct sample attributes
    // Sample name
    $(node).find("td input[data-object = sample]").each(function() {
        data["sample"][$(this).attr("name")] = $(this).val();
    });

    // Sample type
    $(node).find("td select[name = sample_type_id]").each(function() {
        data["sample"]["sample_type_id"] = $(this).val();
    });

    // Sample group
    $(node).find("td select[name = sample_group_id]").each(function() {
        data["sample"]["sample_group_id"] = $(this).val();
    });

    // Custom fields (new fields)
    $(node).find("td input[data-object = custom_fields]").each(function () {
        // Send data only and only if string is not empty
        if ($(this).val().trim()) {
            data["custom_fields"][$(this).attr("name")] = $(this).val();
        }
    });

    // Sample custom fields (existent fields)
    $(node).find("td input[data-object = sample_custom_fields]").each(function () {
        data["sample_custom_fields"][$(this).attr("name")] = $(this).val();
    });

    var url = (saveAction == "update" ? rowData["sampleUpdateUrl"] : $("table#samples").data("create-sample"))
    var type = (saveAction == "update" ? "PUT" : "POST")
    $.ajax({
        url: url,
        type: type,
        dataType: "json",
        data: data,
        success: function (data) {
            sampleAlertMsg(data.flash, "success");
            onClickCancel();
        },
        error: function (e, eData, status, xhr) {
            var data = e.responseJSON;
            clearAllErrors();
            sampleAlertMsgHide();

            if (e.status == 404) {
                sampleAlertMsg(I18n.t("samples.js.not_found_error"), "danger");
                changeToViewMode();
                updateButtons();
            }
            else if (e.status == 403) {
                sampleAlertMsg(I18n.t("samples.js.permission_error"), "danger");
                changeToViewMode();
                updateButtons();
            }
            else if (e.status == 400) {
                if (data["init_fields"]) {
                    var init_fields = data["init_fields"];

                    // Validate sample name
                    if (init_fields["name"]) {
                        var input = $(selectedSample).find("input[name=name]");

                        if (input) {
                            input.closest(".form-group").addClass("has-error");
                            input.parent().append("<span class='help-block'>" + init_fields["name"] + "<br /></span>");
                        }
                    }
                };

                // Validate custom fields
                $.each(data["custom_fields"] || [], function(key, val) {
                    $.each(val, function(key, val) {
                        var input = $(selectedSample).find("input[name=" + key + "]");

                        if (input) {
                            input.closest(".form-group").addClass("has-error");
                            input.parent().append("<span class='help-block'>" + val["value"][0] + "<br /></span>");
                        }
                    });
                });

                // Validate sample custom fields
                $.each(data["sample_custom_fields"] || [], function(key, val) {
                    $.each(val, function(key, val) {
                        var input = $(selectedSample).find("input[name=" + key + "]");

                        if (input) {
                            input.closest(".form-group").addClass("has-error");
                            input.parent().append("<span class='help-block'>" + val["value"][0] + "<br /></span>");
                        }
                    });
                });
            }
        }
    });
}

// Enable/disable edit button
function updateButtons() {
    if (currentMode=="viewMode") {
        $("#importSamplesButton").removeClass("disabled");
        $("#importSamplesButton").prop("disabled",false);
        $("#addSample").removeClass("disabled");
        $("#addSample").prop("disabled",false);
        $("#addNewColumn").removeClass("disabled");
        $("#addNewColumn").prop("disabled",false);

        if (rowsSelected.length == 1) {
            $("#editSample").prop("disabled", false);
            $("#editSample").removeClass("disabled");
            $("#deleteSamplesButton").prop("disabled", false);
            $("#deleteSamplesButton").removeClass("disabled");
            $("#exportSamplesButton").removeClass("disabled");
            $("#exportSamplesButton").prop("disabled",false);
            $("#exportSamplesButton").on("click", function() { $('#form-export').submit(); });
            $("#assignSamples").removeClass("disabled");
            $("#assignSamples").prop("disabled", false);
            $("#unassignSamples").removeClass("disabled");
            $("#unassignSamples").prop("disabled", false);
        }
        else if (rowsSelected.length == 0) {
            $("#editSample").prop("disabled", true);
            $("#editSample").addClass("disabled");
            $("#deleteSamplesButton").prop("disabled", true);
            $("#deleteSamplesButton").addClass("disabled");
            $("#exportSamplesButton").addClass("disabled");
            $("#exportSamplesButton").prop("disabled",true);
            $("#exportSamplesButton").off("click");
            $("#assignSamples").addClass("disabled");
            $("#assignSamples").prop("disabled", true);
            $("#unassignSamples").addClass("disabled");
            $("#unassignSamples").prop("disabled", true);
        }
        else {
            $("#editSample").prop("disabled", true);
            $("#editSample").addClass("disabled");
            $("#deleteSamplesButton").prop("disabled", false);
            $("#deleteSamplesButton").removeClass("disabled");
            $("#exportSamplesButton").removeClass("disabled");
            $("#exportSamplesButton").prop("disabled",false);
            $("#exportSamplesButton").on("click", function() { $('#form-export').submit(); });
            $("#assignSamples").removeClass("disabled");
            $("#assignSamples").prop("disabled", false);
            $("#unassignSamples").removeClass("disabled");
            $("#unassignSamples").prop("disabled", false);
        }
    }
    else if (currentMode=="editMode") {
            $("#importSamplesButton").addClass("disabled");
            $("#importSamplesButton").prop("disabled",true);
            $("#addSample").addClass("disabled");
            $("#addSample").prop("disabled",true);
            $("#editSample").addClass("disabled");
            $("#editSample").prop("disabled",true);
            $("#addNewColumn").addClass("disabled");
            $("#addNewColumn").prop("disabled", true);
            $("#exportSamplesButton").addClass("disabled");
            $("#exportSamplesButton").off("click");
            $("#deleteSamplesButton").addClass("disabled");
            $("#deleteSamplesButton").prop("disabled",true);
            $("#assignSamples").addClass("disabled");
            $("#assignSamples").prop("disabled", true);
            $("#unassignSamples").addClass("disabled");
            $("#unassignSamples").prop("disabled", true);
    }
}

// Clear all has-error tags
function clearAllErrors() {
    // Remove any validation errors
    $(selectedSample).find(".has-error").each(function() {
        $(this).removeClass("has-error");
        $(this).find("span").remove();
    });

    // Remove any alerts
    $("#alert-container").find("div").remove();
}

// Restore previous table
function onClickCancel() {
    table.ajax.reload();

    changeToViewMode();
    updateButtons();
}

function onClickAddSample() {
    changeToEditMode();
    updateButtons();

    saveAction = "create";
    $.ajax({
        url: $("table#samples").data("new-sample"),
        type: "GET",
        dataType: "json",
        success: function (data) {
            var tr = document.createElement("tr")
            $("table#samples thead tr").children("th").each(function(i) {
                var th = $(this);
                if ($(th).attr("id") == "checkbox") {
                    var td = createTdElement("");
                    $(td).html($("#saveSample").clone());
                    tr.appendChild(td);
                }
                else if ($(th).attr("id") == "assigned") {
                   var td = createTdElement("");
                    $(td).html($("#cancelSave").clone());
                    tr.appendChild(td);
                }
                else if ($(th).attr("id") == "sample-name") {
                    var input = changeToInputField("sample", "name", "");
                    tr.appendChild(createTdElement(input));
                }
                else if ($(th).attr("id") == "sample-type") {
                    var colIndex = getColumnIndex("#sample-type")
                    if (colIndex) {
                        var selectType = createSampleTypeSelect(data["sample_types"], -1);
                        var td = createTdElement("");
                        td.appendChild(selectType[0]);
                        tr.appendChild(td);
                    }
                }
                else if ($(th).attr("id") == "sample-group") {
                    var colIndex = getColumnIndex("#sample-group")
                    if (colIndex) {
                        var selectGroup = createSampleGroupSelect(data["sample_groups"], -1);
                        var td = createTdElement("");
                        td.appendChild(selectGroup[0]);
                        tr.appendChild(td);
                    }
                }
                else if ($(th).hasClass("custom-field")) {
                    var input = changeToInputField("custom_fields", th.attr("id"), "");
                    tr.appendChild(createTdElement(input));
                }
                else {
                    // Column we don't care for, just add empty td
                    tr.appendChild(createTdElement(""));
                }
            });
            $("table#samples").prepend(tr);
            selectedSample = tr;

            // Init dropdown with icons
            $("select[name=sample_group_id]").selectpicker();
            $("select[name=sample_type_id]").selectpicker();
        },
        error: function (e, eData, status, xhr) {
            if (e.status == 403)
                sampleAlertMsg(I18n.t("samples.js.permission_error"), "danger");
            changeToViewMode();
            updateButtons();
        }
    });

}

// Handle enter key
$(document).off("keypress").keypress(function(event) {
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if(currentMode == "editMode" && keycode == '13'){
        $("#saveSample").click();
        return false;
    }
});

// Helper functions
function getColumnIndex(id) {
    if (id < 0) return false;
    return table.column(id).index("visible");
}

// Takes object and surrounds it with input
function changeToInputField(object, name, value) {
    return "<div class='form-group'><input class='form-control' data-object='" + object + "' name='" + name + "' value='" + value + "'></input></div>";
}

// Return td element with content
function createTdElement(content) {
    var td = document.createElement("td");
    td.innerHTML = content;
    return td;
}

/**
 * Creates select dropdown for sample type
 * @param data List of sample types
 * @param selected Selected sample type id
 */
function createSampleTypeSelect(data, selected) {
    var $selectType = $("<select></select>").attr("name",  "sample_type_id").addClass("show-tick");

    var $option = $("<option></option>").attr("value", -1).text(I18n.t("samples.table.no_type"))
    $selectType.append($option);

    $.each(data, function(i, val) {
        var $option = $("<option></option>").attr("value", val["id"]).text(val["name"]);
        $selectType.append($option);
    });
    $selectType.val(selected);
    return $selectType;
}

/**
 * Creates select dropdown for sample group
 * @param data List of sample groups
 * @param selected Selected sample group id
 */
function createSampleGroupSelect(data, selected) {
    var $selectGroup = $("<select></select>").attr("name",  "sample_group_id").addClass("show-tick");

    var $span = $("<span></span>").addClass("glyphicon glyphicon-asterisk");
    var $option = $("<option></option>").attr("value", -1).text(I18n.t("samples.table.no_group"))
    .attr("data-icon", "glyphicon glyphicon-asterisk");
    $selectGroup.append($option);

    $.each(data, function(i, val) {
        var $span = $("<span></span>").addClass("glyphicon glyphicon-asterisk").css("color", val["color"]);
        var $option = $("<option></option>").attr("value", val["id"]).text(val["name"])
        .attr("data-content", $span.prop("outerHTML") + " " + val["name"]);

        $selectGroup.append($option);
    });
    $selectGroup.val(selected);
    return $selectGroup;
}

function changeToViewMode() {
    currentMode = "viewMode";

    // $("#saveCancel").hide();

    // Table specific stuff
    table.button(0).enable(true);
}

function changeToEditMode() {
    currentMode = "editMode";

    // $("#saveCancel").show();

    // Table specific stuff
    table.button(0).enable(false);
}