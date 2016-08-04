// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

(function(){

  // Initialize new experiment form
  function initializeNewExperimentModal(){
    $("#new-experiment")
    .on("ajax:beforeSend", function(){
      animateSpinner();
    })
    .on("ajax:success", function(e, data){
      $('body').append($.parseHTML(data.html));
      $('#new-experiment-modal').modal('show',{
        backdrop: true,
        keyboard: false,
      });
    })
    .on("ajax:error", function() {
      animateSpinner(null, false);
      // TODO
    })
    .on("ajax:complete", function(){
      animateSpinner(null, false);
    });
  }

  // Initialize edit experiment form
  function initializeEditExperimentsModal(){
    $.each($(".experiment-panel"), function(){
      var id = '#edit-experiment-modal-' + $(this).data('id');
      $(this)
      .on("ajax:beforeSend", function(){
        animateSpinner();
      })
      .on("ajax:success", function(e, data){
        console.log("request success");
        $('body').append($.parseHTML(data.html));
        $(id).modal('show',{
          backdrop: true,
          keyboard: false,
        });
      })
      .on("ajax:error", function() {
        animateSpinner(null, false);
        // TODO
      })
      .on("ajax:complete", function(){
        animateSpinner(null, false);
      });
    });
  }

  // init modals
  initializeNewExperimentModal();
  initializeEditExperimentsModal();
})();
