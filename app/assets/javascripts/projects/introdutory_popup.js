(function(){
  // display introductory modal
  if( Cookies.get('popup-release-shown') !== 'yes'){
    $("#introductory-popup-modal").modal('show',{
      backdrop: true,
      keyboard: false,
    });
    Cookies.set('popup-release-shown', 'yes', { expires: 7300 });
  }
})();
