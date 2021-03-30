function pageNumbers() {
  var vars = {};
  var paramsKey = ['frompage', 'topage', 'page', 'webpage', 'section', 'subsection', 'subsubsection'];
  var params = document.location.search.substring(1).split('&');

  params.forEach(function(p) {
    var param = p.split('=', 2);
    vars[param[0]] = decodeURIComponent(param[1]);
  });
  paramsKey.forEach(function(key) {
    var elements = document.getElementsByClassName(key);
    for(var i = 0; i < elements.length; i += 1) {
      elements[i].textContent = vars[key];
    }
  });
}
