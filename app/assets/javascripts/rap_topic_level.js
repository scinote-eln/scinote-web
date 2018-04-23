// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// Build the HTML select dropdown for Topic Levels
function generateTopicDropdown(data){
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
        '<div id="rapTopicLevelSelect" class="form-group">',
        '<label class="control-label" for="rap_topic_level">RAP Topic Level</label>',
        '<select class="form-control" onchange="selectRapTopicLevel(this)" onfocus="resetRapTopicLevelChildren()">',
        '<option value="" selected disabled hidden></option>', options, "</select></div>"
    ]
    // Remove in case it already exists, then insert new Topic Level Select HTML
    $('#rapTopicLevelSelect').remove();
    $('#rapProgramLevelSelect').after(dropdownHTML.join(""));
}

function selectRapTopicLevel(el){
    var topicLevelID = el.value;
    // Get all RapProjectLevels for this topicLevelID
    var url = window.location.protocol + "//" + window.location.host + "/rap_project_level/" + topicLevelID;
    $.ajax({
        url: url,
        type: "GET",
        dataType: "json",
        success: function (data) {
            generateProjectDropdown(data);
        },
        error: function (err) {
          // TODO
          console.log("Couldn't retrieve this Topic Level's owned Project Levels.");
          console.log(err);
        }
    });
}

function resetRapTopicLevelChildren(){
    $("#rapProjectLevelSelect").remove();
    $("#rapTaskLevelSelect").remove();
}
