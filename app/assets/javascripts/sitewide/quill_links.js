//= require quill

// Globally overwrite links handling in Quill rich text editor
var Link = Quill.import('formats/link');
Link.sanitize = function(url) {
  if (url.includes('http:') || url.includes('https:')) {
    return url;
  }
  return 'http://' + url;
};
