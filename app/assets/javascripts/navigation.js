/* Loading overlay for search */
$("#search-bar").submit(function (){
  if( $("#update-canvas") ){
    $(document.body).spin(true);
    setTimeout(function(){
      $(".spinner").remove();
    }, 1000);
  } else {
    animateSpinner();
  }
});

