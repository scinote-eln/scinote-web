/*
 * Add parameter to provided specified URL.
 */
function addParam(url, param, value) {
  var a = document.createElement('a'), regex = /(?:\?|&amp;|&)+([^=]+)(?:=([^&]*))*/gi;
  var params = {}, match, str = []; a.href = url;
  while (match = regex.exec(a.search)) {
    if (encodeURIComponent(param) != match[1]) {
      str.push(match[1] + (match[2] ? "=" + match[2] : ""));
    }
  }
  str.push(encodeURIComponent(param) + (value ? "=" + encodeURIComponent(value) : ""));
  a.search = str.join("&");
  return a.href;
}

/*
 * Get URL parameter value.
 */
function getParam(param, asArray) {
  return document.location.search.substring(1).split('&').reduce(function(p,c) {
    var parts = c.split('=', 2).map(function(param) { return decodeURIComponent(param); });
    if(parts.length == 0 || parts[0] != param) return (p instanceof Array) && !asArray ? null : p;
    return asArray ? p.concat(parts.concat(true)[1]) : parts.concat(true)[1];
  }, []);
}

$(document).on('turbolinks:load', function() {
  initFormSubmitLinks();
});
