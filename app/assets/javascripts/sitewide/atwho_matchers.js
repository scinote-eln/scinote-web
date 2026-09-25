// Reimplements the two trigger-matching regexes that used to live inside the vendored at.js
// plugin. `subtext` is the field's text content from its start up to the current caret.
// Both return the matched query string (without the flag character) or null when there's no
// active match ending exactly at the caret.
var AtWhoMatchers = (function() {
  'use strict';

  var UNICODE_RANGE_START = decodeURI('%C3%80');
  var UNICODE_RANGE_END = decodeURI('%C3%BF');

  function escapeFlag(flag) {
    return flag.replace(/[-[\]/{}()*+?.\\^$|]/g, '\\$&');
  }

  // Reproduces at.js's built-in default matcher, used for the '@' user-mention trigger. Note
  // `shouldStartWithSpace` is intentionally passed as `false` for '@' by the caller: the previous
  // config (`startsWithSpace: true`) used a misspelled at.js option name, so the real
  // `startWithSpace` behavior was never actually enabled for '@' - only for '#'. Preserved as-is.
  function defaultMatcher(flag, subtext, shouldStartWithSpace) {
    var cleanedFlag = escapeFlag(flag);
    if (shouldStartWithSpace) cleanedFlag = '(?:^|\\s)' + cleanedFlag;

    var regexp = new RegExp(
      cleanedFlag + '([A-Za-z' + UNICODE_RANGE_START + '-' + UNICODE_RANGE_END + '0-9_+-]*)$|' +
      cleanedFlag + '([^\\x00-\\xff]*)$', 'gi'
    );
    var match = regexp.exec(subtext);
    if (match) return match[1] || match[2] || '';
    return null;
  }

  // Custom matcher for the '#' reference-menu trigger, ported verbatim from the previous
  // implementation (character class allows letters/digits/underscore/slash/colon/whitespace/
  // parens/dot/plus/hyphen, so multi-word queries with spaces keep matching). Only `match[1]` is
  // ever read here, exactly as before - the third alternative (non-Latin query text) is
  // intentionally left unread, reproducing an existing quirk where a unicode query after '#' is
  // detected but returns an empty query string rather than the actual typed text.
  function referenceMatcher(flag, subtext, shouldStartWithSpace) {
    var cleanedFlag = escapeFlag(flag);
    if (shouldStartWithSpace) cleanedFlag = '(?:^|\\s)' + cleanedFlag;

    var regexp = new RegExp(
      cleanedFlag + '$|' +
      cleanedFlag + '(\\S[A-Za-z' + UNICODE_RANGE_START + '-' + UNICODE_RANGE_END + '0-9_/:\\s)(.+-]*)$|' +
      cleanedFlag + '(\\S[^\\x00-\\xff]*)$', 'gi'
    );
    var match = regexp.exec(subtext);
    if (match) return (match[1] || '').trim();
    return null;
  }

  return {
    defaultMatcher: defaultMatcher,
    referenceMatcher: referenceMatcher
  };
}());
