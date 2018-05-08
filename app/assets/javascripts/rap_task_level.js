// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// Build the HTML select dropdown for Task Levels
function generateTaskDropdown(data, edit_suffix){
    // Generate option fields
    var options = [];
    for(var i in data){
        if(data[i].id){
            var option = [
                '<option value="', data[i].id, '">', data[i].name, '</option>'
            ];
            options.push(option.join(""));
        }
    }
    var dropdownHTML = [
        '<div id="rapTaskLevelSelect', edit_suffix, '" class="form-group">',
        '<label class="control-label" for="rap_task_level">RAP Task Level</label>',
        '<select name="project[rap_task_level_id]" class="form-control" onchange="selectRapTaskLevel(this, \'',
        edit_suffix, '\')">',
        '<option value="" selected disabled hidden></option>', options, "</select></div>"
    ]
    // Remove in case it already exists, then insert new Task Level Select HTML
    var remDivID = '#rapTaskLevelSelect' + edit_suffix
    var addDivID = '#rapProjectLevelSelect' + edit_suffix;
    $(remDivID).remove();
    $(addDivID).after(dropdownHTML.join(""));
}

function selectRapTaskLevel(el, edit_suffix){
    // Do nothing...
}