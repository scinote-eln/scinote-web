/* eslint-disable no-unused-vars */
function pageNumbers() {
  var vars = {};
  var paramsKey = ['frompage', 'topage', 'page', 'webpage', 'section', 'subsection', 'subsubsection'];
  var params = document.location.search.substring(1).split('&');

  var pageOffset = document.getElementsByClassName('pagination')[0].dataset.pageOffset;

  params.forEach(function(p) {
    var param = p.split('=', 2);
    vars[param[0]] = decodeURIComponent(param[1]);
  });
  paramsKey.forEach(function(key) {
    var elements = document.getElementsByClassName(key);
    var i;
    for (i = 0; i < elements.length; i += 1) {
      if (key === 'page' || key === 'topage') {
        elements[i].textContent = parseInt(vars[key], 10) + parseInt(pageOffset, 10);
      } else {
        elements[i].textContent = vars[key];
      }
    }
  });
}

pageNumbers();
