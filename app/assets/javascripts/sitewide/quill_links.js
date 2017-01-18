

// Globally overwrite links handling in Quill rich text editor
// var Link = Quill.import('formats/link');
// Link.sanitize = function(url) {
//   if (url.includes('http:') || url.includes('https:')) {
//     return url;
//   }
//   return 'http://' + url;
// };
//
// function openLinksInNewTab() {
//   _.each($('.ql-editor a'), function(el) {
//     if ($(el).attr('target') !== '_blank') {
//       $(el).attr('target', '_blank');
//     }
//   });
// }
//
// $(document).ready(function(){
//   openLinksInNewTab();
// });
