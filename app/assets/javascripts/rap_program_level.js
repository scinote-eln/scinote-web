// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function selectRapProgramLevel(el){
    var programLevelID = el.value;
    console.log(programLevelID);
    // Get all RapTopicLevels for this programLevelID
    $.ajax({
        url: "",
        type: "GET",
        dataType: "json",
        success: function (data) {
            console.log(data);
        }
    });
}