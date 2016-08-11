// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

(function(){

  // Create ajax hook on given 'element', which should return modal with 'id' =>
  // show that modal
  function initializeModal(element, id){
    $(element)
    .on("ajax:beforeSend", function(){
      animateSpinner();
    })
    .on("ajax:success", function(e, data){
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
  }

  // Initialize dropdown actions on experiment:
  // - edit
  // - clone
  function initializeDropdownActions(){
    // { buttonClass: modalName } mappings
    // click on buttonClass summons modalName dialog
    modals = {
      '.edit-experiment': '#edit-experiment-modal-',
      '.clone-experiment': '#clone-experiment-modal-'
    }

    $.each($(".experiment-panel"), function(){
      var $expPanel = $(this);
      $.each(modals, function(buttonClass, modalName) {
        var id = modalName + $expPanel.data('id');
        initializeModal($expPanel.find(buttonClass), id);
      });
    });
  }

  // Bind modal to new-experiment action
  initializeModal($("#new-experiment"), '#new-experiment-modal');

  // Bind modal to all actions listed on dropdown accesible from experiment
  // panel
  initializeDropdownActions();
})();
