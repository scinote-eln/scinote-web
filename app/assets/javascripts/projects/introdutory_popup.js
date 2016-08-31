(function(){
  // display introductory modal
  if( Cookies.get('popup-already-shown') !== 'yes'){
    $("#introductory-popup-modal").modal('show',{
      backdrop: true,
      keyboard: false,
    });
    Cookies.set('popup-already-shown', 'yes', { expires: 7300 });
  }
})();
