/*
 * Truncate long strings where is necessary.
 */
function truncateLongString( el, chars ) {
  if($.type(el) !== 'string'){
    var input = $.trim(el.text());
  } else {
    var input = $.trim(el);
  }

  var html = "";
  if( $.type(el) !== 'string' &&
      el.children().hasClass('fas')) {
    html = el.children()[0];
  }

  if( input.length >= chars ){
    if($.type(el) != 'string') {
      var newText = el.text().slice(0, chars);
    }else {
      var newText = el.slice(0, chars);
    }
    for( var i = newText.length; i > 0; i--){
      if(newText[i] === ' ' && i > 10){
        newText = newText.slice(0, i);
        break;
      }
    }

    if ( html ) {
      el.text(html.outerHTML + newText + '...' );
    } else {
      if($.type(el) === 'string'){
        return newText + '...';
      } else {
      el.text(newText + '...' );
      }
    }
  } else {
    return el;
  }
}

/*
 * Usefull for converting locals messages to error format
 * (i.e. no dot at the end).
 */
String.prototype.strToErrorFormat = function() {
	var length = this.length;
	if (this[length - 1] === ".") {
		length -= 1;
	}
	return this.slice(0, length);
}
