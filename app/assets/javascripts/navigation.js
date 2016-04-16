/* Loading overlay for search */
$("#search-bar").submit(function (){
  animateSpinner(document.body);
});

/* Loading suggestions */
$('#autocomplete').autocomplete({
    serviceUrl: '/search/search_options',
    dataType: 'json',
});

  
