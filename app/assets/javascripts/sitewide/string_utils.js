/*
 * Truncate long strings where is necessary.
 */
function truncateLongString( el, chars ) {
  var input = $.trim(el.text());

  var html = "";
  if( el.children().hasClass("glyphicon") ){
    html = el.children()[0];
  }

  if( input.length  >= chars){
    var newText = el.text().slice(0, chars);
    for( var i = newText.length; i > 0; i--){
      if(newText[i] === ' ' && i > 10){
        newText = newText.slice(0, i);
        break;
      }
    }
  el.html(html.outerHTML + newText + '...' );
  }
}

/*
 * Usefull for converting locals messages to error format
 * (i.e. lower cased capital and no dot at the end).
 */
String.prototype.strToErrorFormat = function() {
	var length = this.length;
	if (this[length - 1] === ".") {
		length -= 1;
	}
	return this.charAt(0).toLowerCase() + this.slice(1, length);
}
