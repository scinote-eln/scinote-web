// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function rapTaskLevelTrigger(edit_suffix, hidden) {
    var opt = $('select option:contains("RAP Not Required")');
    opt.prop('checked', true);
    opt.prop('selected', true);
    // var e = document.getElementById('rapTaskLevelSelector');
    // selectRapProgramLevel(e, '', hidden);
}

// Build the HTML select dropdown for Task Levels
function generateTaskDropdown(data, edit_suffix, hidden, notReq){
    // Generate option fields
    var options = ['<option value=""></option>'];
    for(var i in data){
        if(data[i].id){
            var option = [
                '<option value="', data[i].id, '">', data[i].name, '</option>'
            ];
            options.push(option.join(""));
        }
    }
    var dropdownHTML = [
        '<div id="rapTaskLevelSelect', edit_suffix, '" class="form-group"', hidden, '>',
        '<label class="control-label" for="rap_task_level">RAP Task Level</label>',
        '<select id="rapTaskLevelSelector"', ' name="project[rap_task_level_id]" class="form-control" ',
        'onchange="selectRapTaskLevel(this, \'', edit_suffix, '\')">', options, "</select></div>"
    ]
    // Remove in case it already exists, then insert new Task Level Select HTML
    var remDivID = '#rapTaskLevelSelect' + edit_suffix
    var addDivID = '#rapProjectLevelSelect' + edit_suffix;
    $(remDivID).remove();
    $(addDivID).after(dropdownHTML.join(""));
    
    if(notReq) rapTaskLevelTrigger(edit_suffix, hidden);
}

function selectRapTaskLevel(el, edit_suffix){
    // Do nothing...
}