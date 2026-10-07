// Trigger-boundary check for the '#' reference and '@' mention flags. The query itself is no
// longer typed into the host field (it's typed into the flyout's own search box - see
// smart_annotation_flyout.vue), so all this needs to answer is "was `flag` just typed at a valid
// boundary position, ending exactly at the caret".
var AtWhoMatchers = (function() {
  'use strict';

  // '#' only triggers at the start of the field or after whitespace; '@' triggers anywhere,
  // including mid-word. This reproduces the previous matchers' trigger rules exactly (the '@'
  // case preserves a long-standing quirk - see git history around SCI-13558 - where a misspelled
  // at.js option name meant `startWithSpace` was never actually enabled for '@').
  function isTriggerFlag(flag, subtext, requireLeadingSpace) {
    if (!subtext || subtext.charAt(subtext.length - 1) !== flag) return false;
    if (!requireLeadingSpace) return true;

    var charBefore = subtext.charAt(subtext.length - 2);
    return charBefore === '' || /\s/.test(charBefore);
  }

  return {
    isTriggerFlag: isTriggerFlag
  };
}());
