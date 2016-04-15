/* Loading overlay for search */
var base_url = window.location.protocol + "//" + window.location.host;
$("#search-bar").submit(function (){
  animateSpinner(document.body);
});

$('#autocomplete').autocomplete({
    serviceUrl: '/search/search_options',
    dataType: 'json',
    
});

  
