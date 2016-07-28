// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

(function(){

  // Initialize new experiment form
  function initializeNewExperimentModal(){
    $("#new-experiment")
    .on("ajax:beforeSend", function(){
      animateSpinner(this);
    })
    .on("ajax:success", function(e, data){
      $('body').append($.parseHTML(data.html));
      $('#new-experiment-modal').modal('show',{
        backdrop: true,
        keyboard: false,
      });
    })
    .on("ajax:error", function() {
      animateSpinner(this, false);
      // TODO
    })
    .on("ajax:complete", function(){
      animateSpinner(this, false);
    });
  }

  initializeNewExperimentModal();
})();
