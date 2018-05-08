// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// Build the HTML select dropdown for Topic Levels
function generateTopicDropdown(data, edit_suffix){
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
        '<div id="rapTopicLevelSelect', edit_suffix, '" class="form-group">',
        '<label class="control-label" for="rap_topic_level">RAP Topic Level</label>',
        '<select class="form-control" onchange="selectRapTopicLevel(this, \'', edit_suffix,
        '\')" required>',
        '<option value="" selected disabled hidden></option>', options, "</select></div>"
    ]
    // Remove in case it already exists, then insert new Topic Level Select HTML
    var remDivID = '#rapTopicLevelSelect' + edit_suffix
    var addDivID = '#rapProgramLevelSelect' + edit_suffix;
    $(remDivID).remove();
    $(addDivID).after(dropdownHTML.join(""));
}

function selectRapTopicLevel(el, edit_suffix){
    var topicLevelID = el.value;
    // Get all RapProjectLevels for this topicLevelID
    var url = window.location.protocol + "//" + window.location.host + "/rap_project_level/" + topicLevelID;
    $.ajax({
        url: url,
        type: "GET",
        dataType: "json",
        success: function (data) {
            resetRapTopicLevelChildren();
            generateProjectDropdown(data, edit_suffix);
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
    // Reset the Edit children as well.
    $("#rapProjectLevelSelectEdit").remove();
    $("#rapTaskLevelSelectEdit").remove();
}
