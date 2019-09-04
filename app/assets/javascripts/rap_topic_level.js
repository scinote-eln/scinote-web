// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function rapTopicLevelTrigger(edit_suffix, hidden) {
    var opt = $('select option:contains("RAP Not Required")');
    opt.prop('checked', true);
    opt.prop('selected', true);
    var e = document.getElementById('rapTopicLevelSelector');
    selectRapTopicLevel(e, edit_suffix, hidden);
}

// Build the HTML select dropdown for Topic Levels
function generateTopicDropdown(data, edit_suffix, hidden, notReq){
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
        '<div id="rapTopicLevelSelect', edit_suffix, '" class="form-group" ', hidden, '>',
        '<label class="control-label" for="rap_topic_level">RAP Topic Level</label>',
        '<select id="rapTopicLevelSelector" class="form-control" onchange="selectRapTopicLevel(this, \'',
        edit_suffix, '\')" required>',options, "</select></div>"
    ]
    // Remove in case it already exists, then insert new Topic Level Select HTML
    var remDivID = '#rapTopicLevelSelect' + edit_suffix
    var addDivID = '#rapProgramLevelSelect' + edit_suffix;
    $(remDivID).remove();
    $(addDivID).after(dropdownHTML.join(""));

    if(notReq) rapTopicLevelTrigger(edit_suffix, hidden);
}

function selectRapTopicLevel(el, edit_suffix, hidden){
    var text = el.options[el.selectedIndex].text;
    var topicLevelID = el.value;
    // Get all RapProjectLevels for this topicLevelID
    var url = window.location.protocol + "//" + window.location.host + "/rap_project_level/" + topicLevelID;
    $.ajax({
        url: url,
        type: "GET",
        dataType: "json",
        success: function (data) {
            resetRapTopicLevelChildren();
            generateProjectDropdown(data, edit_suffix, hidden, text === "RAP Not Required");
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
