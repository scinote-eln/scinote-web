// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// Build the HTML select dropdown for Project Levels
function generateProjectDropdown(data){
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
        '<div id="rapProjectLevelSelect" class="form-group">',
        '<label class="control-label" for="rap_project_level">RAP Project Level</label>',
        '<select class="form-control" onchange="selectRapProjectLevel(this)" onfocus="resetRapProjectLevelChildren()">',
        '<option value="" selected disabled hidden></option>', options, "</select></div>"
    ]
    // Remove in case it already exists, then insert new Project Level Select HTML
    $('#rapProjectLevelSelect').remove();
    $('#rapTopicLevelSelect').after(dropdownHTML.join(""));
}

function selectRapProjectLevel(el){
    var projectLevelID = el.value;
    // Get all RapTaskLevels for this projectLevelID
    var url = window.location.protocol + "//" + window.location.host + "/rap_task_level/" + projectLevelID;
    $.ajax({
        url: url,
        type: "GET",
        dataType: "json",
        success: function (data) {
            generateTaskDropdown(data);
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
}
