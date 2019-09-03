// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// After selecting a RAP Program Level, retrieve all its Topic Levels
function selectRapProgramLevel(el, edit_suffix){
    var text = el.options[el.selectedIndex].text;
    if(text === "RAP Not Required"){
        autoSelectTopicDropdown(text, edit_suffix);
        return;
    }
    var programLevelID = el.value;
    // Get all RapTopicLevels for this programLevelID
    var url = window.location.protocol + "//" + window.location.host + "/rap_topic_level/" + programLevelID;
    $.ajax({
        url: url,
        type: "GET",
        dataType: "json",
        success: function (data) {
            resetRapProgramLevelChildren();
            generateTopicDropdown(data, edit_suffix);
        },
        error: function (err) {
          // TODO
          console.log("Couldn't retrieve this Program Level's owned Topic Levels.");
          console.log(err);
        }
    });
}

function resetRapProgramLevelChildren(){
    $("#rapTopicLevelSelect").remove();
    $("#rapProjectLevelSelect").remove();
    $("#rapTaskLevelSelect").remove();
    // Reset the Edit children as well.
    $("#rapTopicLevelSelectEdit").remove();
    $("#rapProjectLevelSelectEdit").remove();
    $("#rapTaskLevelSelectEdit").remove();
}