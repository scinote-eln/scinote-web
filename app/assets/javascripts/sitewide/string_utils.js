/* eslint-disable no-unused-vars */
/* eslint-disable consistent-return */
/* eslint-disable no-extend-native */
const parser = new DOMParser();

/*
 * Unescape HTML entities (e.g. &amp;, &#39;)
 */

function decodeHtmlEntities(htmlString) {
  const parsed = parser.parseFromString(htmlString, 'text/html');

  return parsed.documentElement.textContent;
}

/*
 * Truncate long strings where is necessary.
 */
function truncateLongString(el, chars) {
  let input = ($.type(el) !== 'string') ? $.trim(el.text()) : $.trim(el);

  let html = '';
  if ($.type(el) !== 'string'
      && el.children().hasClass('fas')) {
    html = el.children()[0];
  }

  if (input.length >= chars) {
    let newText = ($.type(el) !== 'string') ? el.text().slice(0, chars) : el.slice(0, chars);

    for (let i = newText.length; i > 0; i -= 1) {
      if (newText[i] === ' ' && i > 10) {
        newText = newText.slice(0, i);
        break;
      }
    }

    if (html) {
      el.text(html.outerHTML + newText + '...');
    } else {
      if ($.type(el) === 'string') {
        return newText + '...';
      }
      el.text(newText + '...');
      return el;
    }
  } else {
    return el;
  }
}

/*
 * Useful for converting locals messages to error format
 * (i.e. no dot at the end).
 */
String.prototype.strToErrorFormat = function() {
  let length = this.length;
  if (this[length - 1] === '.') {
    length -= 1;
  }
  return this.slice(0, length);
};
