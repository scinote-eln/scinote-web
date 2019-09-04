// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function rapProjectLevelTrigger(edit_suffix, hidden) {
    console.log('rapProjectLevelTrigger');
    var opt = $('select option:contains("RAP Not Required")');
    opt.prop('checked', true);
    opt.prop('selected', true);
    var e = document.getElementById('rapProjectLevelSelector');
    console.log(e);
    selectRapProjectLevel(e, edit_suffix, hidden);
}

// Build the HTML select dropdown for Project Levels
function generateProjectDropdown(data, edit_suffix, hidden, notReq){
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
        '<div id="rapProjectLevelSelect', edit_suffix, '" class="form-group" ', hidden, '>',
        '<label class="control-label" for="rap_project_level">RAP Project Level</label>',
        '<select id="rapProjectLevelSelector" class="form-control" onchange="selectRapProjectLevel(this, \'',
        edit_suffix, '\')" required>', options, "</select></div>"
    ]
    // Remove in case it already exists, then insert new Project Level Select HTML
    var remDivID = '#rapProjectLevelSelect' + edit_suffix
    var addDivID = '#rapTopicLevelSelect' + edit_suffix;
    $(remDivID).remove();
    $(addDivID).after(dropdownHTML.join(""));
    
    if(notReq) rapProjectLevelTrigger(edit_suffix, hidden);
}

function selectRapProjectLevel(el, edit_suffix, hidden){
    var text = el.options[el.selectedIndex].text;
    var projectLevelID = el.value;
    // Get all RapTaskLevels for this projectLevelID
    var url = window.location.protocol + "//" + window.location.host + "/rap_task_level/" + projectLevelID;
    $.ajax({
        url: url,
        type: "GET",
        dataType: "json",
        success: function (data) {
            resetRapProjectLevelChildren();
            generateTaskDropdown(data, edit_suffix, hidden, text === "RAP Not Required");
        },
        error: function (err) {
          // TODO
          console.log("Couldn't retrieve this Project Level's owned Task Levels.");
          console.log(err);
        }
    });
}

function resetRapProjectLevelChildren(){
    $("#rapTaskLevelSelect").remove();
    // Reset the Edit children as well.
    $("#rapTaskLevelSelectEdit").remove();
}
