// Truncate long strings where is necessary
function truncateLongString( el, chars ) {
  var input = $.trim(el.text());

  if( input.length  >= chars){
    var newText = el.text().slice(0, chars);
    for( var i = newText.length; i > 0; i--){
      if(newText[i] === ' '){
        newText = newText.slice(0, i);
        break;
      }
    }
  el.text(newText + '...');
  }
}

// Usefull for converting locals messages to form
// format (i.e. lower cased capital and no dot)
String.prototype.strToFormFormat = function() {
	var length = this.length;
	if (this[length - 1] === ".") {
		length -= 1;
	}
	return this.charAt(0).toLowerCase() + this.slice(1, length);
}